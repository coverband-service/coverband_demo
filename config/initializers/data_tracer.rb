# Use a few technique to map runtime code activity to lines
# COVERBAND_DISABLE_AUTO_START=true DATA_TRACER=true bundle exec rails c
#
# NOTE: This entire section of code is an experiment for a technical talk
# beware as below there be dragons.
if ENV['DATA_TRACER']=='true'
  current_root = Dir.pwd
  file = './tmp/data_file_data.json'

  current_exception = nil
  occuring_exception = nil
  event_id = nil
  current_trace = nil
  previous_return = nil
  current_dump = nil
  file_data = {}
  background_started = false
  redis_url = ENV['REDIS_URL']
  redis = Redis.new(url: redis_url)

  BindingDumper::MagicObjects.register(Rails)
  BindingDumper::MagicObjects.register(PostsController)

  puts 'starting tracer'
  # call stack
  # https://github.com/Shopify/rotoscope/issues/16
  # gc?
  # in memory
  # https://bugs.ruby-lang.org/issues/15854
  # https://stackoverflow.com/questions/34751724/how-can-i-inspect-what-is-the-default-value-for-optional-parameter-in-rubys-met
  line_trace = TracePoint.new(:line) do |tp|
    if tp.path.start_with?(current_root) &&
       !tp.path.include?('vendor') &&
       !tp.path.include?('data_tracer.rb') &&
       !tp.path.include?('test') &&
       !tp.path.include?('.erb')
      current_trace = Kernel.caller_locations[0...20]

      # hack to start background tracer
      if tp.path.match('/app/models/post.rb') && tp.lineno == 11 && background_started == false
        background_started = true
        puts 'starting background tracer'
        Thread.new do
          loop do
            sleep(20)
            puts 'background capture'
            capture_traces(file_data, redis)
          end
        end
      end

      # code = File.open(tp.path, 'r') { |f| f.readlines[tp.lineno - 1] }
      if tp.path.match('/app/models/post.rb') ||
         tp.path.match('/app/controllers/posts_controller.rb')
        current_dump = begin
                  tp.binding.dump
                 rescue => e
                  puts "dumper had an error"
                  { failed: 'binding dumper failed' }
                end
      end

      # initialize
      file_data[tp.path] = {} unless file_data[tp.path]
      file_data[tp.path][tp.lineno] = {} unless file_data[tp.path][tp.lineno]

      # values
      file_data[tp.path][tp.lineno]['recent_bindings'] = [] unless file_data[tp.path][tp.lineno]['recent_bindings']
      file_data[tp.path][tp.lineno]['recent_bindings'] << current_dump unless (file_data[tp.path][tp.lineno]['recent_bindings'].length > 5 || file_data[tp.path][tp.lineno]['recent_bindings'].include?(current_dump))

      # stack trace
      file_data[tp.path][tp.lineno]['caller_traces'] = [] unless file_data[tp.path][tp.lineno]['caller_traces']
      file_data[tp.path][tp.lineno]['caller_traces'] << current_trace.join(', ') unless (file_data[tp.path][tp.lineno]['caller_traces'].length > 5 || file_data[tp.path][tp.lineno]['caller_traces'].include?(current_trace.join(', ')))
    end
  end
  line_trace.enable

  ###
  # Monkey patch a current bug in sentry send_event async
  # https://github.com/getsentry/raven-ruby/issues/800
  ###
  module Raven
    class Instance
      def capture_type(obj, options = {})
        unless configuration.capture_allowed?(obj)
          logger.debug("#{obj} excluded from capture: #{configuration.error_messages}")
          return false
        end

        message_or_exc = obj.is_a?(String) ? "message" : "exception"
        options[:configuration] = configuration
        options[:context] = context
        if (evt = Event.send("from_" + message_or_exc, obj, options))
          yield evt if block_given?
          if configuration.async?
            begin
              # We have to convert to a JSON-like hash, because background job
              # processors (esp ActiveJob) may not like weird types in the event hash
              # configuration.async.call(evt.to_json_compatible)
              configuration.async.call(evt)
            rescue => ex
              logger.error("async event sending failed: #{ex.message}")
              send_event(evt)
            end
          else
            send_event(evt)
          end
          Thread.current["sentry_#{object_id}_last_event_id".to_sym] = evt.id
          evt
        end
      end
    end
  end

  exception_tracer = TracePoint.new(:raise) do |tp|
    current_exception = tp.raised_exception
    # link_to it via https://sentry.io/api/0/organizations/coverband-demo/issues/?limit=25&project=1497449&query=28d935d10f8a4084b3511b4baa958046&shortIdLookup=1&statsPeriod=14d
    if current_exception && current_exception.backtrace && event_id
      Rails.logger.info "tracepoint capturing exception: #{current_exception.inspect}"
      current_exception.backtrace.each do |line|
        err_path = line.split(':').first rescue ''
        lineno = line.split(':')[1] rescue ''
        Rails.logger.info "path #{err_path} #{lineno}"

        # filter non app code
        next unless err_path.start_with?(current_root)
        next if err_path.include?('vendor')
        next if err_path.include?('data_tracer')

        Rails.logger.info "capturing path #{err_path} #{lineno}"

        # initialize
        file_data[err_path] = {} unless file_data[err_path]
        file_data[err_path][lineno] = {} unless file_data[err_path][lineno]

        file_data[err_path][lineno]['exception_traces'] = [] unless file_data[err_path][lineno]['exception_traces']
        unless (file_data[err_path][lineno]['exception_traces'].length > 5 || file_data[err_path][lineno]['exception_traces'].include?(event_id))
          file_data[err_path][lineno]['exception_traces'] << event_id
          Rails.logger.info "adding exception trace #{event_id}"
        end
      end
    end
  end
  exception_tracer.enable

  Raven.configure do |config|
    config.async = lambda do |event|
      event_response = Raven.send_event(event)
      event_id = if event_response.is_a?(Hash)
                   event_response['event_id']
                 else
                   event_response.id
                 end
      Rails.logger.info "Raven capturing event #{event_id}"
      # event.respond_to?(:backtrace) ? event.backtrace : event_response['exception']['values'][0]['stacktrace']
    end
  end

  def capture_traces(file_data, redis)
    if file_data['/Users/danmayer/projects/coverband_demo/app/controllers/posts_controller.rb'] ||
      file_data['/Users/danmayer/projects/coverband_demo/app/models/post.rb']
      puts 'trace data:'
      puts "file_data posts_controller: #{file_data['/Users/danmayer/projects/coverband_demo/app/controllers/posts_controller.rb']}"
      puts "file_data post: #{file_data['/Users/danmayer/projects/coverband_demo/app/models/post.rb']}"
    end

    ###
    # begin
    #   manually deep merge the data
    #   previous_data = Marshal.load(redis.get('data_tracer'))
        # file_data.each_pair do |file,lines|
        #   if previous_data['file']
        #     lines.each_pair do |line_key, values|
        #       if previous_data[err_path][lineno][line_key]
        #          file_data[err_path][lineno][line_key] = (file_data[err_path][lineno][line_key] + previous_data[err_path][lineno][line_key]).uniq
        #       end
        #     end
        #   end
        # end
    #   file_data = file_data.merge(previous_data)
    # rescue => error
    #   Rails.logger.info "failure restoring previous data trace #{error}"
    # end
    ###

    dump = Marshal.dump(file_data)
    redis.set('data_tracer', dump)
  end

  at_exit do
    begin
      capture_traces(file_data, redis)
    rescue
      # ignore heroku precompile:assets error
      puts "at_exit capture error"
    end

    # JSON doesn't store as utf-8
    # File.open(file, 'w') {|f| f.write(file_data.to_json) }
    # File.open("#{file}.#{Process.pid}", 'wb') { |f| f.write(dump) }
  end
end

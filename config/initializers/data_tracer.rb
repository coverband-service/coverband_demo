# Use a few technique to map runtime code activity to lines
# COVERBAND_DISABLE_AUTO_START=true DATA_TRACER=true bundle exec rails c
#
# NOTE: This entire section of code is an experiment for a technical talk
# beware as below there be dragons.
#
# DO NOT USE IN PRODUCTION IT COULD EXPOSE YOUR ENV & DB SECRETS
if ENV['DATA_TRACER'] == 'true'
  current_root = Dir.pwd
  file = './tmp/data_file_data.json'

  current_exception = nil
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

  puts 'starting data_tracer'
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
            sleep(30)
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

  exception_tracer = TracePoint.new(:raise) do |tp|
    current_exception = tp.raised_exception
    # link_to it via https://sentry.io/api/0/organizations/coverband-demo/issues/?limit=25&project=1497449&query=28d935d10f8a4084b3511b4baa958046&shortIdLookup=1&statsPeriod=14d
    if current_exception && current_exception.backtrace && event_id
      Rails.logger.info "tracepoint capturing exception: #{current_exception}"
      current_exception.backtrace.each do |line|
        err_path = line.split(':').first rescue ''
        lineno = line.split(':')[1].to_i rescue ''

        # filter non app code
        next unless err_path.start_with?(current_root)
        next if err_path.include?('vendor')
        next if err_path.include?('data_tracer')

        # initialize
        file_data[err_path] = {} unless file_data[err_path]
        file_data[err_path][lineno] = {} unless file_data[err_path][lineno]

        file_data[err_path][lineno]['exception_traces'] = [] unless file_data[err_path][lineno]['exception_traces']
        unless (file_data[err_path][lineno]['exception_traces'].length > 5 || file_data[err_path][lineno]['exception_traces'].include?(event_id))
          file_data[err_path][lineno]['exception_traces'] << event_id
          Rails.logger.info "added exception trace #{err_path} #{lineno} #{event_id}"
        end
      end
    end
  end
  exception_tracer.enable

  Raven.configure do |config|
    config.async = lambda do |event|
      event_response = Raven.send_event(event)
      event_id = if event_response.is_a?(Hash)
                   event_response["event_id"] || event_response[:event_id]
                 else
                   event.id
                 end
      Rails.logger.info "Raven capturing event #{event_id}"
    end
  end

  def capture_traces(file_data, redis)
    if file_data['/Users/danmayer/projects/coverband_demo/app/controllers/posts_controller.rb'] ||
      file_data['/Users/danmayer/projects/coverband_demo/app/models/post.rb']
      puts 'trace data:'
      puts "file_data posts_controller: #{file_data['/Users/danmayer/projects/coverband_demo/app/controllers/posts_controller.rb']}"
      puts "file_data post: #{file_data['/Users/danmayer/projects/coverband_demo/app/models/post.rb']}"
    end

    ### manually deep merge the data
    begin
      previous_data = Marshal.load(redis.get('data_tracer'))
      file_data.each_pair do |file, lines|
        if previous_data[file]
          previous_lines = previous_data[file]
          all_lines = lines + previous_lines.uniq

          all_lines.each do |line_no|
            current_values = file_data[file][line_no]
            previous_values = previous_data[file][line_no]

            if current_values && previous_values
              current_values.keys.each do |line_key|
                if previous_data[file][line_no][line_key]
                  file_data[file][line_no][line_key] = (file_data[file][line_no][line_key] + previous_data[file][line_no][line_key]).uniq
                end
              end
            elsif previous_values
              previous_values.keys.each do |line_key|
                file_data[file][line_no][line_key] = previous_data[file][line_no][line_key]
              end
            end
          end
        end
      end
    rescue => error
      Rails.logger.info "failure restoring previous data trace #{error}"
    end

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

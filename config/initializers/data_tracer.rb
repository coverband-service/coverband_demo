# Map all code lines back to tests that execute them
# COVERBAND_DISABLE_AUTO_START=true DATA_TRACER=true bundle exec rails c
if ENV['DATA_TRACER']=='true'
  current_root = Dir.pwd
  file = './tmp/data_file_data.json'

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

  Raven.configure do |config|
    config.async = lambda do |event|
      event = Raven.send_event(event)
      event_id = if event.is_a?(Hash)
                   Rails.logger.info "event hash #{event.inspect}"
                   'c24c8409d6fb4b94883d70232364fb38'
                 else
                   Rails.logger.info "capturing event #{event.id}"
                   event.id
                 end

      # link_to it via https://sentry.io/api/0/organizations/coverband-demo/issues/?limit=25&project=1497449&query=28d935d10f8a4084b3511b4baa958046&shortIdLookup=1&statsPeriod=14d
      err.backtrace.each do |line|
        err_path = line.split(':').first
        lineno = line.split(':')[1]

        # filter none app code
        next unless err_path.start_with?(current_root)


        file_data[err_path][lineno]['exception_traces'] = [] unless file_data[err_path][lineno]['exception_traces']
        file_data[err_path][lineno]['exception_traces'] << event_id unless (file_data[err_path][lineno]['exception_traces'].length > 5 || file_data[err_path][lineno]['exception_traces'].include?(event_id))
      end
    end
  end

  def capture_traces(file_data, redis)
    if file_data['/Users/danmayer/projects/coverband_demo/app/controllers/posts_controller.rb'] ||
      file_data['/Users/danmayer/projects/coverband_demo/app/models/post.rb']
      puts 'trace data:'
      puts "file_data posts_controller: #{file_data['/Users/danmayer/projects/coverband_demo/app/controllers/posts_controller.rb']}"
      puts "file_data post: #{file_data['/Users/danmayer/projects/coverband_demo/app/models/post.rb']}"
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

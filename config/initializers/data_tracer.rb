# Map all code lines back to tests that execute them
# COVERBAND_DISABLE_AUTO_START=true DATA_TRACER=true bundle exec rails c
if ENV['DATA_TRACER']
  current_root = Dir.pwd
  file = './tmp/data_file_data.json'

  current_trace = nil
  previous_return = nil
  current_dump = nil
  file_data = {}

  BindingDumper::MagicObjects.register(Rails)
  BindingDumper::MagicObjects.register(PostsController)

  puts 'starting tracer'
  # return_trace = TracePoint.new(:return) do |tp|
  #   if tp.return_value
  #     previous_return = tp.return_value
  #   end
  # end
  # return_trace.enable

  # call stack
  # https://github.com/Shopify/rotoscope/issues/16
  # gc?
  # in memory
  # https://bugs.ruby-lang.org/issues/15854
  # https://stackoverflow.com/questions/34751724/how-can-i-inspect-what-is-the-default-value-for-optional-parameter-in-rubys-met
  line_trace = TracePoint.new(:line) do |tp|
    if tp.path.start_with?(current_root) &&
       !tp.path.include?('data_tracer.rb') &&
       !tp.path.include?('test') &&
       !tp.path.include?('.erb')
      current_trace = Kernel.caller_locations[0...20]

      # code = File.open(tp.path, 'r') { |f| f.readlines[tp.lineno - 1] }
      if tp.path == '/Users/danmayer/projects/coverband_demo/app/models/post.rb' ||
         tp.path == '/Users/danmayer/projects/coverband_demo/app/controllers/posts_controller.rb'
        current_dump = begin
                  tp.binding.dump
                 rescue => e
                  puts "dumper had an error"
                  { failed: 'binding dumper failed' }
                end

        puts "-------------------"
      end

      # puts cod

      #results = tp.binding.eval(code)
      #puts results

      file_data[tp.path] = {} unless file_data[tp.path]
      file_data[tp.path][tp.lineno] = {} unless file_data[tp.path][tp.lineno]

      # values
      file_data[tp.path][tp.lineno]['recent_bindings'] = [] unless file_data[tp.path][tp.lineno]['recent_bindings']
      file_data[tp.path][tp.lineno]['recent_bindings'] << current_dump unless (file_data[tp.path][tp.lineno]['recent_bindings'].length > 5 || file_data[tp.path][tp.lineno]['recent_bindings'].include?(current_dump))

      # stack trace
      file_data[tp.path][tp.lineno]['caller_traces'] = [] unless file_data[tp.path][tp.lineno]['caller_traces']
      file_data[tp.path][tp.lineno]['caller_traces'] << current_trace.join(', ') unless (file_data[tp.path][tp.lineno]['caller_traces'].length > 5 || file_data[tp.path][tp.lineno]['caller_traces'].include?(current_trace))
    end
  end
  line_trace.enable

  at_exit do
    # puts "mapped_tests: "
    # puts tests
    puts "file data: "
    puts file_data['/Users/danmayer/projects/coverband_demo/app/controllers/posts_controller.rb']
    puts file_data['/Users/danmayer/projects/coverband_demo/app/models/post.rb']

    File.open("#{file}.#{Process.pid}", 'wb') { |f| f.write(Marshal.dump(file_data)) }

    #doesn't store as utf-8
    #File.open(file, 'w') {|f| f.write(file_data.to_json) }
  end
end

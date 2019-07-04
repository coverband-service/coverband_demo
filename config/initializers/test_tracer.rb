# Map all code lines back to tests that execute them
# TEST_TRACER=true bundle exec rake
if ENV['TEST_TRACER']
  current_root = Dir.pwd
  file = './tmp/test_file_data.json'

  current_test = nil
  tests = {}
  file_data = {}

  puts 'starting tracer'
  call_trace = TracePoint.new(:call) do |tp|
    if tp.path.start_with?(current_root)
      if tp.defined_class.to_s.match(/Test/)
        #if current_test && current_test != "#{tp.defined_class}\##{tp.method_id}"
        #end
        current_test = "#{tp.defined_class}\##{tp.method_id}"
        puts "setting current_test #{current_test}"
      elsif current_test
        #tests[current_test] = [] unless tests.key?(current_test)
        #tests[current_test] = (tests[current_test] + ["#{tp.defined_class}#{tp.method_id}"])
      end
      # puts  [tp.path, tp.lineno, tp.defined_class, tp.method_id, tp.event]
      # puts tp.inspect
    end
  end
  call_trace.enable

  line_trace = TracePoint.new(:line) do |tp|
    if tp.path.start_with?(current_root) && !tp.path.include?('test')
      if current_test
        file_data[tp.path] = {} unless file_data[tp.path]
        file_data[tp.path][tp.lineno] = {} unless file_data[tp.path][tp.lineno]
        file_data[tp.path][tp.lineno]['invoked_by_test'] = [] unless file_data[tp.path][tp.lineno]['invoked_by_test']
        file_data[tp.path][tp.lineno]['invoked_by_test'] << current_test unless file_data[tp.path][tp.lineno]['invoked_by_test'].include?(current_test)
      end
      # puts  [tp.path, tp.lineno, tp.defined_class, tp.method_id, tp.event]
      # puts tp.inspect
    end
  end
  line_trace.enable

  at_exit do
    # puts "mapped_tests: "
    # puts tests
    puts "file data: "
    puts file_data
    File.open(file, 'w') {|f| f.write(file_data.to_json) }
  end
end

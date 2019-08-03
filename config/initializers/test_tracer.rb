# Map all code lines back to tests that execute them
# TEST_TRACER=true bundle exec rake
if ENV['TEST_TRACER'] && ENV['TEST_TRACER'] != 'false'
  current_root = Dir.pwd
  file = './test/reports/test_file_data.json'

  current_test = nil
  file_data = {}

  puts 'starting tracer'
  call_trace = TracePoint.new(:call) do |tp|
    if tp.path.start_with?(current_root) && !tp.path.include?('vendor')
      if tp.defined_class.to_s.match(/Test/)
        current_test = "#{tp.defined_class}\##{tp.method_id}"
        # puts "setting current_test #{current_test}"
      end
    end
  end
  call_trace.enable

  line_trace = TracePoint.new(:line) do |tp|
    if tp.path.start_with?(current_root) && !tp.path.include?('test') && !tp.path.include?('vendor')
      if current_test
        file_data[tp.path] = {} unless file_data[tp.path]
        file_data[tp.path][tp.lineno] = {} unless file_data[tp.path][tp.lineno]
        file_data[tp.path][tp.lineno]['invoked_by_test'] = [] unless file_data[tp.path][tp.lineno]['invoked_by_test']
        unless file_data[tp.path][tp.lineno]['invoked_by_test'].include?(current_test)
          file_data[tp.path][tp.lineno]['invoked_by_test'] << current_test
        end
      end
    end
  end
  line_trace.enable

  at_exit do
    # puts 'mapped files to tests: '
    # puts file_data
    File.open(file, 'w') { |f| f.write(file_data.to_json) }
  end
end

namespace :smart_tests do
  desc 'pull CI test data'
  task :pull_ci_data do
    artifact_data = `curl https://circleci.com/api/v1.1/project/github/danmayer/coverband_demo/latest/artifacts?circle-token=$COVERBAND_DEMO_CIRCLE_KEY&branch=master&filter=completed`
    test_results_url = JSON.parse(artifact_data).select{ |obj| obj['path'].match(/test_file_data/) }.first['url']
    `curl #{test_results_url}?circle-token=$COVERBAND_DEMO_CIRCLE_KEY > tmp/test_file_data.json`
    puts `cat tmp/test_file_data.json`
  end

  desc 'find tests for line'
  task :for_line do
    # get from diff
    path = ENV['CHANGED_PATH'] || '/app/models/post.rb'
    lineno = ENV['CHANGED_LINE'] || '11'
    test_data = JSON.parse(File.read('tmp/test_file_data.json'))
    # TODO: multiple path
    test_path = test_data[path][lineno]['invoked_by_test'].first['path']
    test_lines = test_data[path][lineno]['invoked_by_test'].map{ |obj| obj['line'] }.join(':')
    # debugger
    puts "running: "
    # TODO replace M with the regex join of method name with --name /(name_1|name_2)/
    cmd = "m #{test_path}:#{test_lines}"
    puts cmd
    exec cmd
  end
end

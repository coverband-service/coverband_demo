namespace :smart_tests do
  desc 'pull CI test data'
  task :pull_ci_data do
    artifact_data = `curl https://circleci.com/api/v1.1/project/github/danmayer/coverband_demo/latest/artifacts?circle-token=$COVERBAND_DEMO_CIRCLE_KEY&branch=master&filter=completed`
    test_results_url = JSON.parse(artifact_data).select{ |obj| obj['path'].match(/test_file_data/) }.first['url']
    `curl #{test_results_url}?circle-token=$COVERBAND_DEMO_CIRCLE_KEY > tmp/test_file_data.json`
    puts `cat tmp/test_file_data.json`
  end
end

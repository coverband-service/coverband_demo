# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

desc 'trigger background job'
task trigger_job: :environment do
  HardWorker.perform_async('bob', 5)
end

desc 'run posts cleanup'
task posts_cleanup: :environment do
  Post.clear_bad_posts(all: true)
end

# DATA_FILE=~/Downloads/data_tracer.txt bundle exec rake process_data_trace
desc 'process data tracer'
task process_data_trace: :environment do
  data_file = ENV['DATA_FILE']

  unless data_file
    puts 'you must set the data file path DATA_FILE'
    exit 1
  end

  all_data = Marshal.load(File.binread(data_file))

  puts 'traces for post model line 11'
  puts all_data['/Users/danmayer/projects/coverband_demo/app/models/post.rb'][11]['caller_traces'].map{ |trace| trace.split(',')[1] }

  puts 'exceptions for post model line 14'
  puts all_data['/Users/danmayer/projects/coverband_demo/app/models/post.rb'][14]['exception_traces']

  all_data['/Users/danmayer/projects/coverband_demo/app/models/post.rb'][11]['recent_bindings']
  b = Binding.load(all_data['/Users/danmayer/projects/coverband_demo/app/models/post.rb'][11]['recent_bindings'].first)

  # this part doesn't work, we should be able to enter into the binding...
  # but we can access and execute in it's context
  # b.pry

  puts 'execution context of posts function line 11'
  puts 'what are the local variables?'
  puts b.eval('local_variables').join(', ')
  puts 'what is the value of the posts variable?'
  puts b.local_variable_get(:posts)
  puts 'what is the value of the posts variable?'
  puts b.local_variable_get(:bad_posts)

  debugger

  # change it
  b.eval('bad_posts = posts.select { |post| true }')
  b.local_variable_get(:bad_posts)
end

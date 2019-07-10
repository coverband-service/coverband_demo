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

desc 'clear data tracer'
task clear_data_trace: :environment do
  redis_url = ENV['REDIS_URL']
  redis = Redis.new(url: redis_url)
  redis.set('data_tracer', '')
end

# DATA_FILE=~/Downloads/data_tracer.txt bundle exec rake process_data_trace
desc 'process data tracer'
task process_data_trace: :environment do
  data_file = ENV['DATA_FILE'] || File.expand_path('~/Downloads/data_tracer.txt')

  unless data_file
    puts 'you must set the data file path DATA_FILE'
    exit 1
  end

  all_data = Marshal.load(File.binread(data_file))

  file_path = all_data.keys.select{ |key| key.match('app/models/post.rb') }.first
  puts "found file at #{file_path}"

  puts 'traces for post model line 11'
  puts all_data[file_path][11]['caller_traces'].map{ |trace| trace.split(',')[1] }
  puts '-------'

  if all_data[file_path][14]
    puts 'exceptions for post model line 14'
    puts all_data[file_path][14]['exception_traces']
  end
  puts '-------'

  all_data[file_path][11]['recent_bindings']
  bind = Binding.load(all_data[file_path][11]['recent_bindings'].first)

  puts 'execution context of posts function line 11'
  puts 'what are the local variables?'
  puts bind.eval('local_variables').join(', ')
  puts '-------'
  puts 'what is the value of the posts variable?'
  puts bind.local_variable_get(:posts).inspect
  puts '-------'
  puts 'what is the value of the bad posts variable?'
  puts bind.local_variable_get(:bad_posts).inspect
  puts '-------'

  debugger

  # this part doesn't work, we should be able to enter into the binding...
  # but we can access and execute in it's context
  # bind.pry
  # change it
  # bind.eval('bad_posts = posts.select { |post| true }')
  # bind.local_variable_get(:bad_posts)
end

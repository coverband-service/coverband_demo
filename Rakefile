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

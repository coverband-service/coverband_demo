class HardWorker
  include Sidekiq::Worker

  def perform(*args)
    Rails.logger.info 'HardWorker: clearing posts'
    Post.clear_bad_posts(all: false)
  end
end

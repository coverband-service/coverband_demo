class HardWorker
  include Sidekiq::Worker

  def perform(*args)
    puts 'work'
    Rails.logger.info 'work'
  end
end

class HomeController < ApplicationController
  before_action :set_notice, only: [:index]

  def index
    @job_count = Sidekiq::Stats.new.processed
  end

  def trigger_jobs
    HardWorker.perform_async('bob', 5)
    redirect_to '/?notice=job queued'
  end

  def data_tracer
    redis_url = ENV['REDIS_URL']
    redis = Redis.new(url: redis_url)
    render plain: redis.get('data_tracer')
  end

  private

  def set_notice
    if params[:notice]
      flash[:notice] = params[:notice]
      redirect_to '/'
    end
  end
end

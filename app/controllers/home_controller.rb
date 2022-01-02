require 'sidekiq/api'

class HomeController < ApplicationController
  before_action :set_notice, only: %i[index]

  def index
    @job_count = Sidekiq::Stats.new.processed
  end

  def trigger_jobs
    HardWorker.perform_async('bob', 5)
    flash[:notice] = 'job queued'
    redirect_back(fallback_location: '/')
  end

  def data_tracer
    if !Rails.env.production? ||
         params[:data_trace_api_key] == ENV['DATA_TRACE_API_KEY']
      redis_url = ENV['REDIS_URL']
      redis = Redis.new(url: redis_url)
      render plain: redis.get('data_tracer')
    else
      render plain: 'invalid API key'
    end
  end

  private

  def set_notice
    if params[:notice]
      flash[:notice] = params[:notice]
      redirect_to '/'
    end
  end
end

class HomeController < ApplicationController
  before_action :set_notice, only: [:index]

  def index
    @job_count = Sidekiq::Stats.new.processed
  end

  def trigger_jobs
    HardWorker.perform_async('bob', 5)
    # flash[:notice] = 'job queued to sidekiq'
    redirect_to '/?notice=job queued to sidekiq job'
  end

  private

  def set_notice
    if params[:notice]
      flash[:notice] = params[:notice]
      redirect_to '/'
    end
  end
end

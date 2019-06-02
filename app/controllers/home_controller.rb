class HomeController < ApplicationController
  before_action :set_notice, only: [:index]

  def index
  end

  def trigger_jobs
    HardWorker.perform_async('bob', 5)
    flash[:notice] = 'job queued'
    redirect_to '/'
  end

  private

  def set_notice
    if params[:notice]
      flash[:notice] = params[:notice]
      redirect_to '/'
    end
  end

end

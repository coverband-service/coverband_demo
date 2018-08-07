class HomeController < ApplicationController

  before_action :set_notice, only: [:index]

  def index
  end

  private

  def set_notice
    if params[:notice]
      flash[:notice] = params[:notice]
      redirect_to '/'
    end
  end

end

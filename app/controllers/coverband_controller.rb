class CoverbandController < ApplicationController
  # TODO move to post endpoints not get

  def update_report
    Coverband::Reporters::SimpleCovReport.report(Coverband.configuration.store, open_report: false)
    flash[:notice] = "coverband coverage updated"
    redirect_to '/'
  end

  def clear
    Coverband.configuration.store.clear!
    flash[:notice] = "coverband coverage cleared"
    redirect_to '/'
  end

end

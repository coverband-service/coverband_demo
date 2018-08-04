# There is nothing that will actually execute this code in the app
# It is hear to show that code coverage on it can't be reached.
class UnreachableController < ApplicationController
  def index
    100.times.do
      Rails.logger.info "you can't get here"
    end
  end
end

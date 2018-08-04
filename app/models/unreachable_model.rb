# This shows a model which should never have code coverage as nothing in the app
# calls this code
class UnreachableModel < ApplicationRecord
  def nothing_to_see
    Rails.logger.info "here"
  end
end

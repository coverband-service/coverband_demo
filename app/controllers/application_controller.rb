class ApplicationController < ActionController::Base
  def local_binding
    binding
  end

  # :nocov:
  def testing_nocov_method
    puts 'no coverage here on purpose'
  end
  # :nocov:
end

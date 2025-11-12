class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
# warn ">>> Loading Category from: #{__FILE__}"

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :require_admin_for_writes

  private

  # Require admin for anything that modifies data.
  # Public GET/HEAD requests stay open.
  def require_admin_for_writes
    return if request.get? || request.head?
    http_basic_admin
  end

  # You can also call this explicitly from controllers for specific actions.
  def ensure_admin!
    http_basic_admin
  end

  def http_basic_admin
    # Skip auth in development (optional). Remove this line if you want it on locally too.
    return if Rails.env.development?

    authenticate_or_request_with_http_basic("Admin Area") do |user, pass|
      expected_user = ENV.fetch("ADMIN_USER", "admin")
      expected_pass = ENV["ADMIN_PASSWORD"].to_s
      # Use secure compare to avoid timing attacks
      ActiveSupport::SecurityUtils.secure_compare(user, expected_user) &&
        ActiveSupport::SecurityUtils.secure_compare(pass, expected_pass)
    end
  end
end


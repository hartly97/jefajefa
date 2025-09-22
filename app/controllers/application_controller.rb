class ApplicationController < ActionController::Base
  
  helper_method :current_user

  private

  # Temporary stub for current_user until authentication is added.
#   def current_user
#     nil #no user => not admin
#     # Everyone is treated as an admin for now
#     OpenStruct.new(admin?: true)
#   end
# end



  # Temporary dev stub until you add real authentication (e.g., Devise).
  # By default, there is *no* logged-in user.
  #
  # To simulate admin for testing:
  #   ENV["DEV_ADMIN"] = "true" bin/rails server
  #
  def current_user
    return nil unless ActiveModel::Type::Boolean.new.cast(ENV["DEV_ADMIN"])
 # Everyone is treated as an admin for now
    require "ostruct"
    OpenStruct.new(admin?: true)
  end

  # Guards admin-only actions (like regenerate_slug)
  def require_admin
    unless current_user&.admin?
      redirect_back fallback_location: root_path,
                    alert: "Admins only."
    end
  end


  def maybe_page(scope)
    scope.respond_to?(:page) ? scope.page(params[:page]) : scope
  end
end
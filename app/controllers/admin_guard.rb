module AdminGuard
  extend ActiveSupport::Concern
  private
  def require_admin!
    unless current_user&.admin?
      redirect_back fallback_location: root_path, alert: "Admins only."
    end
  end
end

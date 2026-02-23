class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [:theme])
  end

  rescue_from CanCan::AccessDenied do |_exception|
    redirect_to root_path, flash: { error: 'You are not authorized to perform this action.' }
  end

  def check_admin!
    redirect_to_home unless current_user.admin_role?
  end

  def redirect_to_home
    redirect_to '/', flash: { error: 'Action failed. Unknown route.' }
    # respond_to do |format|
    #   format.html { redirect_to root_path, error: 'Action failed. You do not have the appropriate access.' }
    # end
  end
end

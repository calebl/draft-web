class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def update_resource(resource, params)
    if params[:password].blank? && params[:password_confirmation].blank?
      params.delete(:password)
      params.delete(:password_confirmation)
      params.delete(:current_password)
      resource.update(params)
    else
      super
    end
  end

  def after_update_path_for(resource)
    edit_user_registration_path
  end
end

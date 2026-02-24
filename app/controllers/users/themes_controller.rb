class Users::ThemesController < ApplicationController
  def update
    new_theme = params[:theme]
    if %w[light dark system].include?(new_theme)
      current_user.update!(theme: new_theme)
    end
    head :ok
  end
end

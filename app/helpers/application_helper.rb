module ApplicationHelper
  def theme_preference
    current_user&.theme || "system"
  end
end

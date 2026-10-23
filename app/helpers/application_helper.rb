module ApplicationHelper
  def theme_preference
    current_user&.theme || "system"
  end

  def feedback_enabled?
    FeedbackController.command.present?
  end
end

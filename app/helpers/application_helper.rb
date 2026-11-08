module ApplicationHelper
  def theme_preference
    current_user&.theme || "system"
  end

  # The stories the offline writing page offers, newest first: id and title only.
  def recent_stories_json
    return '[]' unless current_user

    current_user.stories.order(updated_at: :desc).limit(5).pluck(:id, :title)
                .map { |id, title| { id:, title: } }.to_json
  end
end

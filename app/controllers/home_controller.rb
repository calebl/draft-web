class HomeController < ApplicationController
  layout 'home', only: [:index]

  def index
    @stories = current_user.stories.order(updated_at: :desc).first(3)
    @resume_session = current_user.writing_sessions.where.not(story_id: nil).includes(:story).order(updated_at: :desc).first
  end
end

# frozen_string_literal: true

# controller for stories
class StoriesController < ApplicationController
  load_and_authorize_resource # automatically loads @story and @stories and authorizes them
  before_action :writing_sessions, only: %i[show update]

  def index
    # filter authorized stories down to only the current user's stories
    @stories = @stories.where(user: current_user).order(created_at: :desc)
  end

  def show
    @word_count_total = @writing_sessions.where.not(word_count: nil).map(&:word_count).sum
    @next_outline_item = @story.next_outline_item
  end

  def new; end

  def edit; end

  def create
    @story = current_user.stories.create(story_params)
    @writing_sessions = []

    if @story.valid?
      redirect_to story_path(@story)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @story.update(story_params)
      render :show
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @story.destroy!

    redirect_to stories_path, status: :see_other
  end

  private

  def story_params
    params.expect(story: [:title])
  end

  def writing_sessions
    @writing_sessions = @story.writing_sessions.order(updated_at: :desc)
  end
end

class WritingSessionsController < ApplicationController
  protect_from_forgery with: :exception, if: proc { |c| c.request.format != 'application/json' }
  protect_from_forgery with: :null_session, if: proc { |c| c.request.format == 'application/json' }
  after_action :touch_story, only: %i[create update destroy]
  layout 'home', only: %i[new edit]

  load_and_authorize_resource :story
  load_and_authorize_resource :writing_session, through: :story, shallow: true

  def index
    @writing_sessions = @story.writing_sessions.order(updated_at: :desc)
  end

  # GET /writing_sessions/1
  # GET /writing_sessions/1.json
  def show; end

  # GET /writing_sessions/new
  def new
    @title = 'Compose'
    @writing_session = @story.writing_sessions.create(user_id: current_user.id, text: '')

    redirect_to edit_story_writing_session_path(@story, @writing_session.id)
  end

  # GET /writing_sessions/1/edit
  def edit; end

  # POST /writing_sessions
  # POST /writing_sessions.json
  def create
    text = "<div>#{writing_session_params[:text]}</div>"

    @writing_session = @story.writing_sessions.new(writing_session_params.merge(text:, user_id: current_user.id))
    @writing_session.word_count = @writing_session.calculate_word_count

    respond_to do |format|
      if @writing_session.save
        format.html do
          redirect_to edit_story_writing_session_path(@story, @writing_session.id),
                      notice: 'Session was successfully created.',
                      status: :see_other
        end
        format.json { render json: @writing_session, status: :ok }
      else
        format.html { render :new }
        format.json { render json: @writing_session.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /writing_sessions/1
  # PATCH/PUT /writing_sessions/1.json
  def update
    @writing_session.text += "<div>#{writing_session_params[:text]}</div>"
    @writing_session.word_count = @writing_session.calculate_word_count

    respond_to do |format|
      if @writing_session.save
        format.html { redirect_to edit_story_writing_session_path(@story, @writing_session.id), status: :see_other }
        format.json { render json: @writing_session, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: @writing_session.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH /writing_sessions/1/move
  def move
    target_story = current_user.stories.find_by(id: params[:target_story_id])

    if target_story.nil?
      redirect_to story_writing_session_path(@story, @writing_session),
                  alert: 'Choose one of your stories to move this session to.',
                  status: :see_other
    elsif target_story == @story
      redirect_to story_writing_session_path(@story, @writing_session), status: :see_other
    else
      @writing_session.update!(story: target_story)
      @story.touch
      target_story.touch
      redirect_to story_writing_session_path(target_story, @writing_session),
                  notice: "Session moved to #{target_story.title}.",
                  status: :see_other
    end
  end

  # DELETE /writing_sessions/1
  # DELETE /writing_sessions/1.json
  def destroy
    @writing_session.destroy
    respond_to do |format|
      format.html { redirect_to story_path(@story), notice: 'Session was successfully destroyed.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  # Only allow a list of trusted parameters through.
  def writing_session_params
    params.expect(writing_session: [:text])
  end

  def word_count_per_day
    WritingSession.where(user_id: current_user.id).select('date(created_at) as session_date, sum(word_count) as total_words').group('date(created_at)')
  end

  def touch_story
    @story.try(:touch)
  end
end

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
  # Sessions are only started by a POST to create; Turbo prefetches GET links on hover.
  def new
    redirect_to story_path(@story)
  end

  # GET /writing_sessions/1/edit
  def edit; end

  # POST /writing_sessions
  # POST /writing_sessions.json
  def create
    # The phone recreates a session deleted elsewhere by sending its unsaved paragraph
    # here; if that already happened and only the reply was lost, answer with that session.
    return render(json: applied_paragraph_session, status: :ok) if applied_paragraph_session

    # New Session and Write post no text: they start an empty session.
    text = params.key?(:writing_session) ? "<div>#{writing_session_params[:text]}</div>" : ''

    @writing_session = @story.writing_sessions.new(text:, user_id: current_user.id)
    @writing_session.word_count = @writing_session.calculate_word_count

    respond_to do |format|
      if save_with_paragraph_id
        format.html do
          redirect_to edit_story_writing_session_path(@story, @writing_session.id),
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
    # A paragraph sent again because its reply never reached the phone is not added twice.
    return render(json: applied_paragraph_session, status: :ok) if applied_paragraph_session

    text = writing_session_params[:text]

    respond_to do |format|
      if append_with_paragraph_id(text)
        format.html { redirect_to edit_story_writing_session_path(@story, @writing_session.id), status: :see_other }
        format.json { render json: @writing_session, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: @writing_session.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /writing_sessions/1
  # DELETE /writing_sessions/1.json
  def destroy
    @writing_session.destroy
    respond_to do |format|
      format.html { redirect_to after_destroy_path, notice: I18n.t('writing_sessions.destroyed'), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  # Deleting from the all-sessions list returns there instead of the story page.
  def after_destroy_path
    params[:show_all].present? ? story_writing_sessions_path(@story) : story_path(@story)
  end

  # The session that already holds the paragraph with this id, when it was applied before.
  def applied_paragraph_session
    return if params[:paragraph_id].blank?

    @applied_paragraph_session ||=
      SavedParagraph.joins(:writing_session)
                    .find_by(paragraph_id: params[:paragraph_id].to_s,
                             writing_sessions: { user_id: current_user.id })&.writing_session
  end

  # Save the session and, when the phone sent a paragraph id, remember it in the same
  # transaction. Two copies of one paragraph racing in keep only the first.
  def save_with_paragraph_id
    WritingSession.transaction do
      next false unless @writing_session.save

      remember_paragraph_id
      true
    end
  rescue ActiveRecord::RecordNotUnique
    applied_paragraph_session_recovered?
  end

  def append_with_paragraph_id(text)
    WritingSession.transaction do
      @writing_session.lock!
      @writing_session.text += "<div>#{text}</div>"
      @writing_session.word_count = @writing_session.calculate_word_count
      next false unless @writing_session.save

      remember_paragraph_id
      true
    end
  rescue ActiveRecord::RecordNotUnique
    applied_paragraph_session_recovered?
  end

  def remember_paragraph_id
    @writing_session.saved_paragraphs.create!(paragraph_id: params[:paragraph_id].to_s) if params[:paragraph_id].present?
  end

  def applied_paragraph_session_recovered?
    @writing_session = applied_paragraph_session
    raise unless @writing_session

    true
  end

  # Only allow a list of trusted parameters through.
  def writing_session_params
    return ActionController::Parameters.new if action_name == 'create' && !params.key?(:writing_session)

    params.expect(writing_session: [:text])
  end

  def word_count_per_day
    WritingSession.where(user_id: current_user.id).select('date(created_at) as session_date, sum(word_count) as total_words').group('date(created_at)')
  end

  def touch_story
    @story.try(:touch)
  end
end

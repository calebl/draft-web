require 'open3'
require 'shellwords'

# Hands feedback typed in the app to a command configured by DRAFT_FEEDBACK_COMMAND.
# The command runs without a shell; the message goes on its stdin.
class FeedbackController < ApplicationController
  MAX_LENGTH = 2000
  UUID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/
  SENT_EXIT_CODES = [0, 3].freeze

  before_action :require_command
  rate_limit to: 5, within: 1.minute, only: :create, with: -> { reject }

  def self.command
    value = ENV.fetch('DRAFT_FEEDBACK_COMMAND', '')
    value.strip.empty? ? nil : Shellwords.split(value)
  end

  def self.screens
    @screens ||= Rails.application.routes.routes.filter_map do |route|
      controller, action = route.defaults.values_at(:controller, :action)
      "#{controller}##{action}" if controller && action
    end.to_set
  end

  def create
    text = params[:text].to_s.strip
    screen = params[:screen].to_s
    request_id = params[:request_id].to_s

    valid?(text, screen, request_id) && sent?(screen, text, request_id) ? accept : reject
  end

  private

  def valid?(text, screen, request_id)
    text.present? && text.length <= MAX_LENGTH && self.class.screens.include?(screen) && request_id.match?(UUID_FORMAT)
  end

  def require_command
    head :not_found unless self.class.command
  end

  def sent?(screen, text, request_id)
    body = "Draft feedback (screen: #{screen})\n\n#{text}\n"
    _output, status = Open3.capture2e(*self.class.command, '--request-id', "draft-feedback-#{request_id}", '--json', '-',
                                      stdin_data: body)
    SENT_EXIT_CODES.include?(status.exitstatus)
  rescue SystemCallError
    false
  end

  def accept
    flash.now[:notice] = I18n.t('feedback.sent')
    render turbo_stream: [
      turbo_stream.replace('feedback', partial: 'shared/feedback', locals: { screen: params[:screen] }),
      turbo_stream.append_all('body', partial: 'shared/flash')
    ]
  end

  # Leaves the form as it is so the typed text survives.
  def reject
    flash.now[:error] = I18n.t('feedback.send_failed')
    render turbo_stream: turbo_stream.append_all('body', partial: 'shared/flash'), status: :unprocessable_entity
  end
end

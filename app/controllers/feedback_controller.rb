require 'open3'
require 'shellwords'

# Hands feedback typed in the app to a command configured by DRAFT_FEEDBACK_COMMAND.
# The command runs without a shell; the message goes on its stdin.
class FeedbackController < ApplicationController
  MAX_LENGTH = 2000
  UUID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/
  SENT_EXIT_CODES = [0, 3].freeze
  USER_AGENT_LENGTH = 300
  DIMENSION_FORMAT = /\A\d{1,5}\z/
  PIXEL_RATIO_FORMAT = /\A\d{1,2}(\.\d{1,4})?\z/

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
    body = ["Draft feedback (screen: #{screen})", *device_lines, '', text, ''].join("\n")
    _output, status = Open3.capture2e(*self.class.command, '--request-id', "draft-feedback-#{request_id}", '--json', '-',
                                      stdin_data: body)
    SENT_EXIT_CODES.include?(status.exitstatus)
  rescue SystemCallError
    false
  end

  # Device fields come from the browser, so only expected shapes are kept and anything else is dropped.
  def device_lines
    device = params[:device].is_a?(ActionController::Parameters) ? params[:device] : {}
    user_agent = device[:user_agent].to_s.gsub(/[[:cntrl:]]/, ' ').squish.first(USER_AGENT_LENGTH)
    [("Device: #{user_agent}" if user_agent.present?), viewport_line(device)].compact
  end

  def viewport_line(device)
    size = size(device, :width, :height)
    return unless size

    visible = size(device, :visible_width, :visible_height)
    ratio = device[:pixel_ratio].to_s
    standalone = device[:standalone].to_s
    line = "Viewport: #{size}"
    line += " (visible #{visible})" if visible && visible != size
    line += " @#{ratio.to_f.to_s.delete_suffix('.0')}x" if ratio.match?(PIXEL_RATIO_FORMAT)
    line += ", standalone: #{standalone == 'true' ? 'yes' : 'no'}" if %w[true false].include?(standalone)
    line
  end

  def size(device, width_key, height_key)
    width, height = device.values_at(width_key, height_key).map(&:to_s)
    "#{width}x#{height}" if width.match?(DIMENSION_FORMAT) && height.match?(DIMENSION_FORMAT)
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

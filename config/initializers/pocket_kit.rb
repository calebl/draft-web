# The header's feedback button, error monitoring, and session replay come from pocket-kit.
# See the corresponding sections in README.md.
PocketKit.configure do |config|
  config.feedback.command_env = 'DRAFT_FEEDBACK_COMMAND'
  config.feedback.heading = 'Draft feedback'
  config.feedback.request_id_prefix = 'draft-feedback'
  config.feedback.sent_exit_codes = [0, 3]

  config.errors.command_env = 'DRAFT_ERRORS_COMMAND'
  config.errors.heading = 'Draft'
  config.errors.request_id_prefix = 'draft-errors'

  config.replay.enabled = true
end

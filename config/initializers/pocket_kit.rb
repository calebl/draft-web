# The header's feedback button, from the pocket-kit gem. See "Feedback" in README.md.
PocketKit.configure do |config|
  config.feedback.command_env = 'DRAFT_FEEDBACK_COMMAND'
  config.feedback.heading = 'Draft feedback'
  config.feedback.request_id_prefix = 'draft-feedback'
  config.feedback.sent_exit_codes = [0, 3]
end

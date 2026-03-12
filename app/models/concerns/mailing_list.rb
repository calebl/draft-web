module MailingList
  MAILER_LITE_GROUP = 111712173989824242

  def subscribe_to_mailing
    return unless Rails.env.production?

    MailerLite.create_group_subscriber(MAILER_LITE_GROUP, { email: email })
  rescue StandardError => e
    Rails.logger.warn("MailerLite subscription failed for #{email}: #{e.message}")
  end

end
module MailingList
  MAILER_LITE_GROUP = 111712173989824242

  def subscribe_to_mailing
    # MailerLite.create_group_subscriber(MAILER_LITE_GROUP, { email: email }) if Rails.env.production?
  end

end
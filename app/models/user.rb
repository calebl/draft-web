class User < ApplicationRecord
  include MailingList

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :writing_sessions, dependent: :destroy
  has_many :stories, dependent: :destroy

  validates :theme, inclusion: { in: %w[light dark system] }

  after_create :subscribe_to_mailing

  def password_required?
    Rails.env.development? ? false : true
  end
end

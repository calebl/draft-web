class User < ApplicationRecord
  LOCAL_EMAIL = 'local@localhost'.freeze

  has_many :writing_sessions, dependent: :destroy
  has_many :stories, dependent: :destroy

  validates :theme, inclusion: { in: %w[light dark system] }

  # Draft runs as a single local user: every request acts as the oldest account,
  # created on first boot when the database has no users yet.
  def self.local
    order(:id).first || create_or_find_by!(email: LOCAL_EMAIL)
  end
end

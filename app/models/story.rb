class Story < ApplicationRecord
  validates :title, presence: true

  belongs_to :user
  has_many :writing_sessions, dependent: :destroy
  has_one :outline, dependent: :destroy
  has_many :outline_items, through: :outline

  def next_outline_item
    outline.outline_items.where(completed: false).order(position: :asc).first if outline
  end
end

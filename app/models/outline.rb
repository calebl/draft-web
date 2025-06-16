class Outline < ApplicationRecord
  belongs_to :story
  has_many :outline_items, -> { order(position: :asc) }, dependent: :destroy, inverse_of: :outline
end

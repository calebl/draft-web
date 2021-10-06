class WritingSession < ApplicationRecord
  belongs_to :user
  belongs_to :story, optional: true

  def calculate_word_count
    text.gsub(/\\n/, ' ').gsub('<div>', ' ').gsub('</div>', ' ').split.size
  end
end

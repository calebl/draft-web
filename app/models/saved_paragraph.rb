# A paragraph id already applied to a writing session, so a resent paragraph is not saved twice.
class SavedParagraph < ApplicationRecord
  belongs_to :writing_session
end

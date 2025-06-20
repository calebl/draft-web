class MoveWritingSessionsIntoStory < ActiveRecord::Migration[6.1]
  def up
    # create story "My Story" for each User (how do I do this???)
    User.find_each do |user|
      story = user.stories.create(title: 'My Story')
      # assign all current writing sessions to this story
      user.writing_sessions.update_all(story_id: story.id)
    end
    # modify story_id column on writing_session to be required
    change_column :writing_sessions, :story_id, :integer, references: :users, null: false, foreign_key: true
  end

  def down 
    # modify story_id column to not be required
    change_column :writing_sessions, :story_id, :integer, references: :users, null: true, foreign_key: true
    # assign all story_id to nil
    User.find_each do |user|
      user.writing_sessions.update_all(story_id: nil)
      # delete "My Story"
      user.stories.find_by(title: 'My Story').destroy
    end
  end
end

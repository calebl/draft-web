# Each paragraph the phone sends carries an id; remembering the ids already applied lets a
# paragraph that is sent again (because the reply never reached the phone) be ignored.
class CreateSavedParagraphs < ActiveRecord::Migration[8.0]
  def change
    create_table :saved_paragraphs do |t|
      t.references :writing_session, null: false, foreign_key: true
      t.string :paragraph_id, null: false
      t.timestamps
    end
    add_index :saved_paragraphs, :paragraph_id, unique: true
  end
end

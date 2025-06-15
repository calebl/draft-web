# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 20_250_612_164_159) do
  create_table 'blazer_audits', force: :cascade do |t|
    t.integer 'user_id'
    t.integer 'query_id'
    t.text 'statement'
    t.string 'data_source'
    t.datetime 'created_at', precision: nil
    t.index ['query_id'], name: 'index_blazer_audits_on_query_id'
    t.index ['user_id'], name: 'index_blazer_audits_on_user_id'
  end

  create_table 'blazer_checks', force: :cascade do |t|
    t.integer 'creator_id'
    t.integer 'query_id'
    t.string 'state'
    t.string 'schedule'
    t.text 'emails'
    t.text 'slack_channels'
    t.string 'check_type'
    t.text 'message'
    t.datetime 'last_run_at', precision: nil
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['creator_id'], name: 'index_blazer_checks_on_creator_id'
    t.index ['query_id'], name: 'index_blazer_checks_on_query_id'
  end

  create_table 'blazer_dashboard_queries', force: :cascade do |t|
    t.integer 'dashboard_id'
    t.integer 'query_id'
    t.integer 'position'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['dashboard_id'], name: 'index_blazer_dashboard_queries_on_dashboard_id'
    t.index ['query_id'], name: 'index_blazer_dashboard_queries_on_query_id'
  end

  create_table 'blazer_dashboards', force: :cascade do |t|
    t.integer 'creator_id'
    t.string 'name'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['creator_id'], name: 'index_blazer_dashboards_on_creator_id'
  end

  create_table 'blazer_queries', force: :cascade do |t|
    t.integer 'creator_id'
    t.string 'name'
    t.text 'description'
    t.text 'statement'
    t.string 'data_source'
    t.string 'status'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['creator_id'], name: 'index_blazer_queries_on_creator_id'
  end

  create_table 'outline_items', force: :cascade do |t|
    t.integer 'outline_id'
    t.string 'text'
    t.boolean 'completed', default: false
    t.integer 'position'
    t.string 'timestamps'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['outline_id'], name: 'index_outline_items_on_outline_id'
  end

  create_table 'outlines', force: :cascade do |t|
    t.integer 'story_id'
    t.integer 'completion'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['story_id'], name: 'index_outlines_on_story_id'
  end

  create_table 'stories', force: :cascade do |t|
    t.string 'title', null: false
    t.integer 'user_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['user_id'], name: 'index_stories_on_user_id'
  end

  create_table 'users', force: :cascade do |t|
    t.string 'email', default: '', null: false
    t.string 'encrypted_password', default: '', null: false
    t.string 'reset_password_token'
    t.datetime 'reset_password_sent_at', precision: nil
    t.datetime 'remember_created_at', precision: nil
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.boolean 'admin_role'
    t.index ['email'], name: 'index_users_on_email', unique: true
    t.index ['reset_password_token'], name: 'index_users_on_reset_password_token', unique: true
  end

  create_table 'writing_sessions', force: :cascade do |t|
    t.integer 'word_count'
    t.text 'text'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.integer 'user_id'
    t.integer 'story_id', null: false
    t.index ['story_id'], name: 'index_writing_sessions_on_story_id'
    t.index ['user_id'], name: 'index_writing_sessions_on_user_id'
  end

  add_foreign_key 'writing_sessions', 'stories'
  add_foreign_key 'writing_sessions', 'users'
end

# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100504184914) do

  create_table "branches", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "classifications", :force => true do |t|
    t.integer  "entry_id"
    t.boolean  "clicked"
    t.boolean  "clicked_title"
    t.boolean  "liked"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "entries", :force => true do |t|
    t.string   "title"
    t.string   "url"
    t.date     "last_modified"
    t.string   "author"
    t.text     "summary"
    t.text     "content"
    t.datetime "published"
    t.integer  "subscription_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "entries", ["id"], :name => "index_entries_on_id"
  add_index "entries", ["published"], :name => "index_entries_on_published"
  add_index "entries", ["subscription_id"], :name => "index_entries_on_subscription_id"
  add_index "entries", ["url"], :name => "index_entries_on_url"

  create_table "metadata", :force => true do |t|
    t.integer  "user_id"
    t.integer  "entry_id"
    t.datetime "read"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "category"
    t.float    "signal_value"
    t.float    "noise_value"
  end

  add_index "metadata", ["entry_id"], :name => "index_metadata_on_entry_id"
  add_index "metadata", ["user_id"], :name => "index_metadata_on_user_id"

  create_table "stream", :force => true do |t|
    t.integer  "entry_id"
    t.float    "rating"
    t.string   "category"
    t.integer  "user_id"
    t.datetime "published"
  end

  create_table "subscriptions", :force => true do |t|
    t.string   "title"
    t.string   "url"
    t.string   "feed_url"
    t.datetime "last_modified"
    t.string   "etag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subscriptions_users", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "subscription_id"
  end

  create_table "users", :force => true do |t|
    t.string   "email",             :null => false
    t.string   "crypted_password",  :null => false
    t.string   "password_salt",     :null => false
    t.string   "persistence_token", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

end

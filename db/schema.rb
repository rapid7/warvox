# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121228171549) do

  add_extension "intarray"

  create_table "dial_jobs", :force => true do |t|
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.text     "range"
    t.integer  "seconds"
    t.integer  "lines"
    t.text     "status"
    t.integer  "progress"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.boolean  "processed"
    t.text     "cid_mask"
  end

  create_table "dial_result_media", :force => true do |t|
    t.integer "dial_result_id"
    t.binary  "audio"
    t.binary  "mp3"
    t.binary  "png_big"
    t.binary  "png_big_dots"
    t.binary  "png_big_freq"
    t.binary  "png_sig"
    t.binary  "png_sig_freq"
  end

  create_table "dial_results", :force => true do |t|
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.text     "number"
    t.integer  "dial_job_id"
    t.integer  "provider_id"
    t.boolean  "completed"
    t.boolean  "busy"
    t.integer  "seconds"
    t.integer  "ringtime"
    t.boolean  "processed"
    t.datetime "processed_at"
    t.text     "cid"
    t.float    "peak_freq"
    t.text     "peak_freq_data"
    t.text     "sig_data"
    t.text     "line_type"
    t.text     "notes"
    t.text     "signatures"
    t.integer  "fprint",                         :array => true
  end

  create_table "projects", :force => true do |t|
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.text     "name"
    t.text     "description"
    t.text     "included"
    t.text     "excluded"
    t.string   "created_by"
  end

  create_table "providers", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.text     "name"
    t.text     "host"
    t.integer  "port"
    t.text     "user"
    t.text     "pass"
    t.integer  "lines"
    t.boolean  "enabled"
  end

  create_table "settings", :force => true do |t|
    t.string   "var",                      :null => false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", :limit => 30
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  add_index "settings", ["thing_type", "thing_id", "var"], :name => "index_settings_on_thing_type_and_thing_id_and_var", :unique => true

  create_table "users", :force => true do |t|
    t.string   "login",                                 :null => false
    t.string   "email"
    t.string   "crypted_password",                      :null => false
    t.string   "password_salt",                         :null => false
    t.string   "persistence_token",                     :null => false
    t.string   "single_access_token",                   :null => false
    t.string   "perishable_token",                      :null => false
    t.integer  "login_count",         :default => 0,    :null => false
    t.integer  "failed_login_count",  :default => 0,    :null => false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.boolean  "enabled",             :default => true
    t.boolean  "admin",               :default => true
  end

end

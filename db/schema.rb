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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20130113004653) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "intarray"

  create_table "call_media", force: true do |t|
    t.integer "call_id",      null: false
    t.integer "project_id",   null: false
    t.binary  "audio"
    t.binary  "mp3"
    t.binary  "png_big"
    t.binary  "png_big_dots"
    t.binary  "png_big_freq"
    t.binary  "png_sig"
    t.binary  "png_sig_freq"
  end

  add_index "call_media", ["call_id"], name: "index_call_media_on_call_id", using: :btree
  add_index "call_media", ["project_id"], name: "index_call_media_on_project_id", using: :btree

  create_table "calls", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "number",                null: false
    t.integer  "project_id",            null: false
    t.integer  "job_id",                null: false
    t.integer  "provider_id",           null: false
    t.boolean  "answered"
    t.boolean  "busy"
    t.text     "error"
    t.integer  "audio_length"
    t.integer  "ring_length"
    t.text     "caller_id"
    t.integer  "analysis_job_id"
    t.datetime "analysis_started_at"
    t.datetime "analysis_completed_at"
    t.float    "peak_freq"
    t.text     "peak_freq_data"
    t.text     "line_type"
    t.integer  "fprint",                             array: true
  end

  add_index "calls", ["job_id"], name: "index_calls_on_job_id", using: :btree
  add_index "calls", ["number"], name: "index_calls_on_number", using: :btree
  add_index "calls", ["provider_id"], name: "index_calls_on_provider_id", using: :btree

  create_table "jobs", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id",               null: false
    t.string   "locked_by"
    t.datetime "locked_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.string   "created_by"
    t.string   "task",                     null: false
    t.binary   "args"
    t.string   "status"
    t.text     "error"
    t.integer  "progress",     default: 0
  end

  add_index "jobs", ["project_id"], name: "index_jobs_on_project_id", using: :btree

  create_table "line_attributes", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "line_id",                       null: false
    t.integer  "project_id",                    null: false
    t.text     "name",                          null: false
    t.binary   "value",                         null: false
    t.string   "content_type", default: "text"
  end

  add_index "line_attributes", ["line_id"], name: "index_line_attributes_on_line_id", using: :btree
  add_index "line_attributes", ["project_id"], name: "index_line_attributes_on_project_id", using: :btree

  create_table "lines", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "number",     null: false
    t.integer  "project_id", null: false
    t.text     "line_type"
    t.text     "notes"
  end

  add_index "lines", ["number"], name: "index_lines_on_number", using: :btree
  add_index "lines", ["project_id"], name: "index_lines_on_project_id", using: :btree

  create_table "projects", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "name",        null: false
    t.text     "description"
    t.text     "included"
    t.text     "excluded"
    t.string   "created_by"
  end

  create_table "providers", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "name",                      null: false
    t.text     "host",                      null: false
    t.integer  "port",                      null: false
    t.text     "user"
    t.text     "pass"
    t.integer  "lines",      default: 1,    null: false
    t.boolean  "enabled",    default: true
  end

  create_table "reportable_cache", force: true do |t|
    t.string   "model_name",       limit: 100,               null: false
    t.string   "report_name",      limit: 100,               null: false
    t.string   "grouping",         limit: 10,                null: false
    t.string   "aggregation",      limit: 10,                null: false
    t.string   "conditions",       limit: 100,               null: false
    t.float    "value",                        default: 0.0, null: false
    t.datetime "reporting_period",                           null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "reportable_cache", ["model_name", "report_name", "grouping", "aggregation", "conditions", "reporting_period"], name: "name_model_grouping_aggregation_period", unique: true, using: :btree
  add_index "reportable_cache", ["model_name", "report_name", "grouping", "aggregation", "conditions"], name: "name_model_grouping_agregation", using: :btree

  create_table "settings", force: true do |t|
    t.string   "var",                   null: false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true, using: :btree

  create_table "signature_fp", force: true do |t|
    t.integer "signature_id", null: false
    t.integer "fprint",                    array: true
  end

  add_index "signature_fp", ["signature_id"], name: "index_signature_fp_on_signature_id", using: :btree

  create_table "signatures", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "name",        null: false
    t.string   "source"
    t.text     "description"
    t.string   "category"
    t.string   "line_type"
    t.integer  "risk"
  end

  create_table "users", force: true do |t|
    t.string   "login",                              null: false
    t.string   "email"
    t.string   "crypted_password",                   null: false
    t.string   "password_salt",                      null: false
    t.string   "persistence_token",                  null: false
    t.string   "single_access_token",                null: false
    t.string   "perishable_token",                   null: false
    t.integer  "login_count",         default: 0,    null: false
    t.integer  "failed_login_count",  default: 0,    null: false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "enabled",             default: true
    t.boolean  "admin",               default: true
  end

end

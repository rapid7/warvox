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

end

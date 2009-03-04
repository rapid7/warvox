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

ActiveRecord::Schema.define(:version => 20090303225838) do

  create_table "dial_jobs", :force => true do |t|
    t.string   "range"
    t.integer  "seconds"
    t.integer  "lines"
    t.string   "status"
    t.integer  "progress"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.boolean  "processed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cid_mask"
  end

  create_table "dial_results", :force => true do |t|
    t.integer  "number"
    t.integer  "dial_job_id"
    t.integer  "provider_id"
    t.boolean  "completed"
    t.boolean  "busy"
    t.integer  "seconds"
    t.integer  "ringtime"
    t.string   "rawfile"
    t.boolean  "processed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "processed_at"
    t.string   "cid"
  end

  create_table "providers", :force => true do |t|
    t.string   "name"
    t.string   "host"
    t.integer  "port"
    t.string   "user"
    t.string   "pass"
    t.integer  "lines"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "enabled"
  end

end

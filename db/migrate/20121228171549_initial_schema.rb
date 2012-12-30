class InitialSchema < ActiveRecord::Migration
	def up

		# Require the intarray extension
		execute("CREATE EXTENSION IF NOT EXISTS intarray")


		create_table :settings do |t|
			t.string :var, :null => false
			t.text   :value, :null => true
			t.integer :thing_id, :null => true
			t.string :thing_type, :limit => 30, :null => true
			t.timestamps
		end

		add_index :settings, [ :thing_type, :thing_id, :var ], :unique => true

		create_table 'users' do |t|
			t.string    :login,               :null => false                # optional, you can use email instead, or both
			t.string    :email,               :null => true                 # optional, you can use login instead, or both
			t.string    :crypted_password,    :null => false                # optional, see below
			t.string    :password_salt,       :null => false                # optional, but highly recommended
			t.string    :persistence_token,   :null => false                # required
			t.string    :single_access_token, :null => false                # optional, see Authlogic::Session::Params
			t.string    :perishable_token,    :null => false                # optional, see Authlogic::Session::Perishability

			# Magic columns, just like ActiveRecord's created_at and updated_at. These are automatically maintained by Authlogic if they are present.
			t.integer   :login_count,         :null => false, :default => 0 # optional, see Authlogic::Session::MagicColumns
			t.integer   :failed_login_count,  :null => false, :default => 0 # optional, see Authlogic::Session::MagicColumns
			t.datetime  :last_request_at                                    # optional, see Authlogic::Session::MagicColumns
			t.datetime  :current_login_at                                   # optional, see Authlogic::Session::MagicColumns
			t.datetime  :last_login_at                                      # optional, see Authlogic::Session::MagicColumns
			t.string    :current_login_ip                                   # optional, see Authlogic::Session::MagicColumns
			t.string    :last_login_ip                                      # optional, see Authlogic::Session::MagicColumns

			t.timestamps
			t.boolean   "enabled", :default => true
			t.boolean   "admin",   :default => true
		end

		create_table 'projects' do |t|
			t.timestamps
			t.text      "name"
			t.text      "description"
			t.text		"included"
			t.text		"excluded"
			t.string	"created_by"
		end

		create_table "dial_jobs" do |t|
			t.timestamps
			t.text		"range"
			t.integer	"seconds"
			t.integer	"lines"
			t.text		"status"
			t.integer	"progress"
			t.datetime	"started_at"
			t.datetime	"completed_at"
			t.boolean	"processed"
			t.text		"cid_mask"
		end

		create_table "dial_results" do |t|
			t.timestamps
			t.text			"number"
			t.integer		"dial_job_id"
			t.integer		"provider_id"
			t.boolean		"completed"
			t.boolean		"busy"
			t.integer		"seconds"
			t.integer		"ringtime"
			t.boolean		"processed"
			t.datetime		"processed_at"
			t.text			"cid"
			t.float			"peak_freq"
			t.text			"peak_freq_data"
			t.text			"sig_data"
			t.text			"line_type"
			t.text			"notes"
			t.text			"signatures"
			t.integer		"fprint", :array => true
		end

		create_table "dial_result_media" do |t|
			t.integer		"dial_result_id"
			t.binary		"audio"
			t.binary		"mp3"
			t.binary		"png_big"
			t.binary		"png_big_dots"
			t.binary		"png_big_freq"
			t.binary		"png_sig"
			t.binary		"png_sig_freq"
		end

		create_table "providers" do |t|
			t.timestamps
			t.text			"name"
			t.text			"host"
			t.integer		"port"
			t.text			"user"
			t.text			"pass"
			t.integer		"lines"
			t.boolean		"enabled"
		end

	end

	def down
		drop_table "providers"
		drop_table "dial_result_media"
		drop_table "dial_results"
		drop_table "dial_jobs"
		drop_table "projects"
		drop_table "users"
		drop_table "settings"
	end
end

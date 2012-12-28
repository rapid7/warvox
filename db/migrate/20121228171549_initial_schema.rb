class InitialSchema < ActiveRecord::Migration
	def up

		# Require the intarray extension
		execute("CREATE EXTENSION IF NOT EXISTS intarray")

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
		remove_table "providers"
		remove_table "dial_result_media"
		remove_table "dial_results"
		remove_table "dial_jobs"
	end
end

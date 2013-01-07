class AddIndexes < ActiveRecord::Migration
	def up
		add_index :jobs, :project_id
		add_index :lines, :number
		add_index :lines, :project_id
		add_index :line_attributes, :line_id
		add_index :line_attributes, :project_id
		add_index :calls, :number
		add_index :calls, :job_id
		add_index :calls, :provider_id
		add_index :call_media, :call_id
		add_index :call_media, :project_id
		add_index :signature_fp, :signature_id
	end

	def down
		remove_index :jobs, :project_id
		remove_index :lines, :number
		remove_index :lines, :project_id
		remove_index :line_attributes, :line_id
		remove_index :line_attributes, :project_id
		remove_index :calls, :number
		remove_index :calls, :job_id
		remove_index :calls, :provider_id
		remove_index :call_media, :call_id
		remove_index :call_media, :project_id
		remove_index :signature_fp, :signature_id
	end
end

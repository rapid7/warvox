class CreateDialJobs < ActiveRecord::Migration
  def self.up
    create_table :dial_jobs do |t|
      t.string :range
      t.integer :seconds
      t.integer :lines
      t.string :status
      t.integer :progress
      t.datetime :started_at
      t.datetime :completed_at
	  t.boolean :processed

      t.timestamps
    end
  end

  def self.down
    drop_table :dial_jobs
  end
end

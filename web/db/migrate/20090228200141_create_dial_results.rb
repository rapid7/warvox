class CreateDialResults < ActiveRecord::Migration
  def self.up
    create_table :dial_results do |t|
      t.text :number
      t.integer :dial_job_id
      t.integer :provider_id
      t.boolean :completed
      t.boolean :busy
      t.integer :seconds
      t.integer :ringtime
      t.text :rawfile
	  t.boolean :processed

      t.timestamps
    end
  end

  def self.down
    drop_table :dial_results
  end
end


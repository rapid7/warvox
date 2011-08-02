class AddCidMaskToDialJobs < ActiveRecord::Migration
  def self.up
    add_column :dial_jobs, :cid_mask, :text
  end

  def self.down
    remove_column :dial_jobs, :cid_mask
  end
end

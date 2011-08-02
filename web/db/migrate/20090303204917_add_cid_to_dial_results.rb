class AddCidToDialResults < ActiveRecord::Migration
  def self.up
    add_column :dial_results, :cid, :text
  end

  def self.down
    remove_column :dial_results, :cid
  end
end

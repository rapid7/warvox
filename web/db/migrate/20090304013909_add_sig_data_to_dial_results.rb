class AddSigDataToDialResults < ActiveRecord::Migration
  def self.up
    add_column :dial_results, :sig_data, :text
  end

  def self.down
    remove_column :dial_results, :sig_data
  end
end


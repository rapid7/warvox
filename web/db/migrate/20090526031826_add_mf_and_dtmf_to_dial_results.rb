class AddMfAndDtmfToDialResults < ActiveRecord::Migration
  def self.up
	  add_column :dial_results, :dtmf, :text
	  add_column :dial_results, :mf, :text
  end

  def self.down
    remove_column :dial_results, :dtmf
    remove_column :dial_results, :mf
  end
end

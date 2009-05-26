class AddMfAndDtmfToDialResults < ActiveRecord::Migration
  def self.up
	  add_column :dial_results, :dtmf, :string
	  add_column :dial_results, :mf, :string
  end

  def self.down
    remove_column :dial_results, :dtmf
    remove_column :dial_results, :mf
  end
end

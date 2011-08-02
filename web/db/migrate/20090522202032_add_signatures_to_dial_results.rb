class AddSignaturesToDialResults < ActiveRecord::Migration
  def self.up
    add_column :dial_results, :signatures, :text
  end

  def self.down
    remove_column :dial_results, :signatures
  end
end

class AddSignaturesToDialResults < ActiveRecord::Migration
  def self.up
    add_column :dial_results, :signatures, :string
  end

  def self.down
    remove_column :dial_results, :signatures
  end
end

class AddFprintToDialResult < ActiveRecord::Migration
  def self.up
    add_column :dial_results, :fprint, 'int[]'
  end

  def self.down
    remove_column :dial_results, :fprint
  end
end


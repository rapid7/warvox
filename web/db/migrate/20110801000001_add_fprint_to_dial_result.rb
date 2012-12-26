class AddFprintToDialResult < ActiveRecord::Migration
  def self.up
  	execute "CREATE EXTENSION intarray"
    add_column :dial_results, :fprint, 'int[]'
  end

  def self.down
    remove_column :dial_results, :fprint
  	execute "DROP EXTENSION intarray"
  end
end

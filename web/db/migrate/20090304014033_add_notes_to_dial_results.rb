class AddNotesToDialResults < ActiveRecord::Migration
  def self.up
    add_column :dial_results, :notes, :text
  end

  def self.down
    remove_column :dial_results, :notes
  end
end

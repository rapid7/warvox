class AddLineTypeToDialResults < ActiveRecord::Migration
  def self.up
    add_column :dial_results, :line_type, :text
  end

  def self.down
    remove_column :dial_results, :line_type
  end
end

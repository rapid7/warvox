class AddLineTypeToDialResults < ActiveRecord::Migration
  def self.up
    add_column :dial_results, :line_type, :string
  end

  def self.down
    remove_column :dial_results, :line_type
  end
end

class AddProcessedAtToDialResult < ActiveRecord::Migration
  def self.up
    add_column :dial_results, :processed_at, :datetime
  end

  def self.down
    remove_column :dial_results, :processed_at
  end
end

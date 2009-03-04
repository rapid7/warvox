class AddEnabledToProviders < ActiveRecord::Migration
  def self.up
    add_column :providers, :enabled, :boolean
  end

  def self.down
    remove_column :providers, :enabled
  end
end

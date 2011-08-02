class AddAudioToDialResult < ActiveRecord::Migration
  def self.up
    add_column :dial_results, :audio, :binary
  end

  def self.down
    remove_column :dial_results, :audio
  end
end


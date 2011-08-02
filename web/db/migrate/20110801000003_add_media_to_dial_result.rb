class AddMediaToDialResult < ActiveRecord::Migration
  def self.up
    add_column :dial_results, :mp3, :binary
    add_column :dial_results, :png_big, :binary
    add_column :dial_results, :png_big_dots, :binary
    add_column :dial_results, :png_big_freq, :binary
    add_column :dial_results, :png_sig, :binary
    add_column :dial_results, :png_sig_freq, :binary
  end

  def self.down
    remove_column :dial_results, :mp3
    remove_column :dial_results, :png_big
    remove_column :dial_results, :png_big_dots
    remove_column :dial_results, :png_big_freq
    remove_column :dial_results, :png_sig
    remove_column :dial_results, :png_sig_freq
  end
end


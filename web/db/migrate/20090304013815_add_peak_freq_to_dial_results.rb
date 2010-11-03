class AddPeakFreqToDialResults < ActiveRecord::Migration
  def self.up
    add_column :dial_results, :peak_freq, :number
  end

  def self.down
    remove_column :dial_results, :peak_freq
  end
end

class AddPeakFreqDataToDialResults < ActiveRecord::Migration
  def self.up
    add_column :dial_results, :peak_freq_data, :text
  end

  def self.down
    remove_column :dial_results, :peak_freq_data
  end
end

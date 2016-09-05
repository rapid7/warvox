# == Schema Information
#
# Table name: providers
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  name       :text             not null
#  host       :text             not null
#  port       :integer          not null
#  user       :text
#  pass       :text
#  lines      :integer          default(1), not null
#  enabled    :boolean          default(TRUE)
#

class Provider < ApplicationRecord
  has_many :dial_results

  validates_presence_of :name, :host, :port, :user, :pass, :lines
  validates_numericality_of :port, less_than: 65536, greater_than: 0
  validates_numericality_of :lines, less_than: 255, greater_than: 0
end

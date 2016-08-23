# == Schema Information
#
# Table name: projects
#
#  id          :integer          not null, primary key
#  created_at  :datetime
#  updated_at  :datetime
#  name        :text             not null
#  description :text
#  included    :text
#  excluded    :text
#  created_by  :string(255)
#

class Project < ApplicationRecord

  validates_presence_of :name
  validates_uniqueness_of :name

  # This is optimized for fast project deletion, even with thousands of calls/jobs/lines
  has_many :lines, :dependent => :delete_all
  has_many :line_attributes, :dependent => :delete_all
  has_many :calls, :dependent => :delete_all
  has_many :call_media, :dependent => :delete_all
  has_many :jobs, :dependent => :delete_all
end

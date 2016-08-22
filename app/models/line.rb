# == Schema Information
#
# Table name: lines
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  number     :text             not null
#  project_id :integer          not null
#  line_type  :text
#  notes      :text
#

class Line < ApplicationRecord
  has_many :line_attributes, :dependent => :delete_all
  belongs_to :project

  def set_attribute(name, value, ctype='text/plain')
    la = LineAttribute.where(line_id: self.id, project_id: self.project_id, name: name).first_or_create
    la.value = value
    la.ctype = ctype
    la.save
    la
  end

  def get_attribute(name)
    LineAttribute.where(:line_id => self[:id], :name => name).first
  end
end

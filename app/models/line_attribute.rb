# == Schema Information
#
# Table name: line_attributes
#
#  id           :integer          not null, primary key
#  created_at   :datetime
#  updated_at   :datetime
#  line_id      :integer          not null
#  project_id   :integer          not null
#  name         :text             not null
#  value        :binary           not null
#  content_type :string(255)      default("text")
#

class LineAttribute < ActiveRecord::Base
  belongs_to :line
  belongs_to :project
end

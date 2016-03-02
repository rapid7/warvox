# == Schema Information
#
# Table name: signatures
#
#  id          :integer          not null, primary key
#  created_at  :datetime
#  updated_at  :datetime
#  name        :text             not null
#  source      :string(255)
#  description :text
#  category    :string(255)
#  line_type   :string(255)
#  risk        :integer
#

class Signature < ActiveRecord::Base
  has_many :signature_fps

end

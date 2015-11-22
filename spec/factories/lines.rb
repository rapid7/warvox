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

FactoryGirl.define do
	factory :line do
		project
		number { Faker::PhoneNumber.phone_number }
	end

end

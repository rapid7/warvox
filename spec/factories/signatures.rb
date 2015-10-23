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

FactoryGirl.define do
	factory :signature do
		name { Faker::Commerce.product_name }
		source { Faker::PhoneNumber.cell_phone }
		description { Faker::Lorem.sentence }
		category { Faker::Lorem.word }
		line_type { Faker::Lorem.word }
		risk { Faker::Lorem.word }
	end

end

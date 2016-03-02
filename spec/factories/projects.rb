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

FactoryGirl.define do
  factory :project do
    name { Faker::Lorem.sentence }
    description { Faker::Lorem.sentence }
  end

end

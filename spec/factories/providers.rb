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

FactoryGirl.define do
  factory :provider do
    name { Faker::Company.name }
    host { Faker::Internet.ip_v4_address }
    port { Faker::Number.between(1, 65535) }
    user { Faker::Internet.user_name }
    pass { Faker::Internet.password(10, 20) }
    lines { Faker::Number.between(1, 254) }
    enabled true
  end

end

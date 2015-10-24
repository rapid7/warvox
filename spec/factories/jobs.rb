# == Schema Information
#
# Table name: jobs
#
#  id           :integer          not null, primary key
#  created_at   :datetime
#  updated_at   :datetime
#  project_id   :integer          not null
#  locked_by    :string(255)
#  locked_at    :datetime
#  started_at   :datetime
#  completed_at :datetime
#  created_by   :string(255)
#  task         :string(255)      not null
#  args         :binary
#  status       :string(255)
#  error        :text
#  progress     :integer          default(0)
#

FactoryGirl.define do
	factory :job do
		project
		task 'dialer'
		args "\x04\b{\t:\nrangeI\"\x0F7632458942\x06:\x06ET:\nlinesi\x0F:\fsecondsi::\rcid_maskI\"\tSELF\x06;\x06T"
		status 'submitted'
		error nil
		range { Faker::PhoneNumber.phone_number }
		cid_mask { Faker::PhoneNumber.phone_number }
		seconds { Faker::Number.between(1, 299) }
		lines { Faker::Number.between(1, 10000) }
	end

end

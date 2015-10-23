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

require 'rails_helper'

RSpec.describe Provider, type: :model do
	## TODO determine if association is unecessary
	# the DialResult model does not exist
	#it { should have_many(:dial_results) }

	it { should validate_presence_of(:name) }
	it { should validate_presence_of(:host) }
	it { should validate_presence_of(:port) }
	it { should validate_presence_of(:user) }
	it { should validate_presence_of(:pass) }
	it { should validate_presence_of(:lines) }
	it { should validate_numericality_of(:port).is_less_than(65536).is_greater_than(0) }
	it { should validate_numericality_of(:lines).is_less_than(255).is_greater_than(0) }

	it "valid record" do
		expect(build(:provider)).to be_valid
	end
end

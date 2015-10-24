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

require 'rails_helper'

RSpec.describe Job, type: :model do
	it { should belong_to(:project) }
	it { should have_many(:calls) }

	it { should validate_presence_of(:project_id) }

	it "valid record" do
		expect(build(:job)).to be_valid
	end
end

# == Schema Information
#
# Table name: calls
#
#  id                    :integer          not null, primary key
#  created_at            :datetime
#  updated_at            :datetime
#  number                :text             not null
#  project_id            :integer          not null
#  job_id                :integer          not null
#  provider_id           :integer          not null
#  answered              :boolean
#  busy                  :boolean
#  error                 :text
#  audio_length          :integer
#  ring_length           :integer
#  caller_id             :text
#  analysis_job_id       :integer
#  analysis_started_at   :datetime
#  analysis_completed_at :datetime
#  peak_freq             :float
#  peak_freq_data        :text
#  line_type             :text
#  fprint                :integer          is an Array
#

require 'rails_helper'

RSpec.describe Call, type: :model do
	it { should belong_to(:project) }
	it { should belong_to(:provider) }
	it { should belong_to(:job) }
	it { should have_one(:call_medium).dependent(:delete) }

	it "valid record" do
		expect(build(:call)).to be_valid
	end
end

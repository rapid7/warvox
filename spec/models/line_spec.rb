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

require 'rails_helper'

RSpec.describe Line, type: :model do
  it { should belong_to(:project) }
  it { should have_many(:line_attributes).dependent(:delete_all) }

  it "valid record" do
    expect(build(:line)).to be_valid
  end
end

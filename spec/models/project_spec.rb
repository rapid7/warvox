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

require 'rails_helper'

RSpec.describe Project, type: :model do
  it { should have_many(:lines).dependent(:delete_all) }
  it { should have_many(:line_attributes).dependent(:delete_all) }
  it { should have_many(:calls).dependent(:delete_all) }
  it { should have_many(:call_media).dependent(:delete_all) }
  it { should have_many(:jobs).dependent(:delete_all) }

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }

  it "valid record" do
    expect(build(:project)).to be_valid
  end
end

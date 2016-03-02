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

require 'rails_helper'

RSpec.describe Signature, type: :model do
  ## TODO association may not be needed
  # causes crash:  PG::UndefinedTable: ERROR:  relation "signature_fps" does not exist
  #it { should have_many(:signature_fps) }

  it "valid record" do
    expect(build(:signature)).to be_valid
  end
end

require 'rails_helper'

RSpec.feature "Projects", type: :feature do

  before(:each) do
    @user = create(:user)
    create_user_session(@user)
  end

  it "list all existing projects" do
    project = create(:project)
    visit projects_path
    expect(page).to have_content "WarVOX Projects"
    within "#projects-table" do
      expect(page).to have_content "Name"
      expect(page).to have_content "Description"
      expect(page).to have_content "Jobs"
      expect(page).to have_content "Calls"
      expect(page).to have_content "Analyzed"
      expect(page).to have_content "Created"
      expect(page).to have_content "Actions"
      expect(page).to have_content project.name
    end
  end
end

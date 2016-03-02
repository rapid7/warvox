module Authlogic
  module TestHelper
    def create_user_session(user)
      visit login_path
      within "#new_user_session" do
        expect(page).to have_content "Username"
        expect(page).to have_content "Password"
        fill_in "user_session_login", with: user.login
        fill_in "user_session_password", with: user.password
        click_button "Sign in"
      end
    end
  end
end

# Make this available to just the request and feature specs
RSpec.configure do |config|
  config.include Authlogic::TestHelper, type: :request
  config.include Authlogic::TestHelper, type: :feature
end
require 'rails_helper'

RSpec.feature "Logins", type: :feature do
  it "login with valid credentials" do
    user = create(:user)
    visit login_path
    within "#new_user_session" do
      expect(page).to have_content "Username"
      expect(page).to have_content "Password"
      fill_in "user_session_login", with: user.login
      fill_in "user_session_password", with: 'RandomPass'
      click_button "Sign in"
    end
    within "div.content" do
      expect(page).to have_content "WarVOX Projects"
    end
  end

  it "failed login with invalid password valid username" do
    user = create(:user)
    visit login_path
    within "#new_user_session" do
      fill_in "user_session_login", with: user.login
      fill_in "user_session_password", with: 'WrongPassword'
      click_button "Sign in"
    end
    expect(page).to have_content "Password is not valid"
  end

  it "failed login with invalid username valid password" do
    user = create(:user)
    visit login_path
    within "#new_user_session" do
      fill_in "user_session_login", with: user.login + "Wrong"
      fill_in "user_session_password", with: 'RandomPass'
      click_button "Sign in"
    end
    expect(page).to have_content "Login is not valid"
  end

  it "failed login with no input entered" do
    visit login_path
    within "#new_user_session" do
      click_button "Sign in"
    end
    expect(page).to have_content "You did not provide any details for authentication."
  end

  it "failed login with no password entered" do
    user = create(:user)
    visit login_path
    within "#new_user_session" do
      fill_in "user_session_login", with: user.login
      click_button "Sign in"
    end
    expect(page).to have_content "Password cannot be blank"
  end
end

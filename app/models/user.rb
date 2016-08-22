# == Schema Information
#
# Table name: users
#
#  id                  :integer          not null, primary key
#  login               :string(255)      not null
#  email               :string(255)
#  crypted_password    :string(255)      not null
#  password_salt       :string(255)      not null
#  persistence_token   :string(255)      not null
#  single_access_token :string(255)      not null
#  perishable_token    :string(255)      not null
#  login_count         :integer          default(0), not null
#  failed_login_count  :integer          default(0), not null
#  last_request_at     :datetime
#  current_login_at    :datetime
#  last_login_at       :datetime
#  current_login_ip    :string(255)
#  last_login_ip       :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  enabled             :boolean          default(TRUE)
#  admin               :boolean          default(TRUE)
#

class User < ApplicationRecord
  include RailsSettings::Extend
  acts_as_authentic do |c|
    c.validate_email_field = false
    c.merge_validates_length_of_password_field_options :minimum => 8
    c.merge_validates_length_of_password_confirmation_field_options :minimum => 8
    c.logged_in_timeout = 1.day
  end
end

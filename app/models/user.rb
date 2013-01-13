class User < ActiveRecord::Base
	include RailsSettings::Extend
	acts_as_authentic do |c|
		c.validate_email_field = false
		c.merge_validates_length_of_password_field_options :minimum => 8
		c.merge_validates_length_of_password_confirmation_field_options :minimum => 8
		c.logged_in_timeout = 1.day
	end
end

all: test

test: install
	bin/verify_install.rb

install: bundler

db:
	@echo "Checking the database.."
	RAILS_ENV=production bundle exec rake db:migrate

bundler:
	@echo "Checking for RubyGems and the Bundler gem..."
	@ruby -rrubygems -e 'require "bundler"; puts "OK"'

	@echo "Validating that 'bundle' is in the path..."
	which bundle

	@echo "Installing missing gems as needed.."
	bundle install

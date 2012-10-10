all: test

test: install
	bin/verify_install.rb
	
install: bundler dtmf2num 
	cp -a src/dtmf2num/dtmf2num bin/

dtmf2num:
	make -C src/dtmf2num/

db:
	@echo "Checking the database.."
	(cd web; RAILS_ENV=production bundle exec rake db:migrate )

bundler:
	@echo "Checking for RubyGems and the Bundler gem..."
	@ruby -rrubygems -e 'require "bundler"; puts "OK"'

	@echo "Validating that 'bundle' is in the path..."
	which bundle
	
	@echo "Installing missing gems as needed.."
	(cd web; bundle install)

clean:
	make -C src/dtmf2num/ clean

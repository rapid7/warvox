all: install

install: iaxrecord ruby-kissfft db
	cp -a src/iaxrecord/iaxrecord bin/
	cp -a src/ruby-kissfft/kissfft.so lib/

iaxrecord:
	make -C src/iaxrecord/

ruby-kissfft:
	( cd src/ruby-kissfft/; ruby extconf.rb )
	make -C src/ruby-kissfft/

db: db_null web/db/production.sqlite3
	@echo "Checking the database.."

db_null:
	find web/db/ -name 'production.sqlite3' -size 0 | xargs -i rm {}

web/db/production.sqlite3: ruby-kissfft
	(cd web; RAILS_ENV=production rake db:migrate )

clean:
	( cd src/ruby-kissfft/; ruby extconf.rb )
	make -C src/ruby-kissfft/ clean
	make -C src/iaxrecord/ clean
	rm -f bin/iaxrecord lib/kissfft.so

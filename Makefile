all: install

install: iaxrecord ruby-kissfft
	cp -a src/iaxrecord/iaxrecord bin/
	cp -a src/ruby-kissfft/kissfft.so lib/

iaxrecord:
	make -C src/iaxrecord/

ruby-kissfft:
	( cd src/ruby-kissfft/; ruby extconf.rb )
	make -C src/ruby-kissfft/

clean:
	( cd src/ruby-kissfft/; ruby extconf.rb )
	make -C src/ruby-kissfft/ clean
	make -C src/iaxrecord/ clean
	rm -f bin/iaxrecord lib/kissfft.so

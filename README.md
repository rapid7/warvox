WarVOX

==
WarVOX is released under a BSD-style license. See docs/LICENSE for more details.

The latest version of this software is available from http://github.com/rapid7/warvox/

Questions and suggestions can be sent to:
 hdm(at)rapid7.com

Installing
--
WarVOX 2.0.0 is still in development and the installation process is not ideal at the moment.

WarVOX requires a Linux operating system, preferably Ubuntu or Debian, but Kali should work as well.

WarVOX requires PostgreSQL 9.1 or newer with the "contrib" package installed for integer array support.

To get started, install the OS-level dependencies:

	$ sudo apt-get install gnuplot lame build-essential libssl-dev libcurl-openssl-dev postgresql postgresql-contrib git-core curl

Clone this repository to the location you want to install WarVOX:

	$ git clone git://github.com/rapid7/warvox.git /home/warvox

Install RVM to obtain Ruby 1.9.3 or later

	$ \curl -L https://get.rvm.io | bash -s stable --autolibs=3 --rails

Configure WarVOX:

	$ cd /home/warvox
	$ make

Configure the PostgreSQL account for WarVOX:

	$ sudo su - postgres
	$ createuser warvox
	$ createdb warvox -O warvox
	$ psql
	psql> alter user warvox with password 'randompass';
	psql> exit

Copy the example database configuration to database.yml:

	$ cp config/database.yml.example config/database.yml

Modify config/database.yml to include the password set previously

Initialize the WarVOX database:
	$ make database

Add an admin account to WarVOX
	$ bin/adduser admin

Start the WarVOX daemons:
	$ bin/warvox.rb 

Access the web interface at http://127.0.0.1:7777/

At this point you can configure a new IAX2 provider, create a project, and start making calls.
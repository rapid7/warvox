# WarVOX

WarVOX is released under a BSD-style license. See docs/LICENSE for more details.

The latest version of this software is available from http://github.com/rapid7/warvox/

Questions and suggestions can be sent to:
 x(at)hdm(dot)io

 - [Installing](#installing)

##installing

WarVOX requires a Linux operating system, preferably Ubuntu or Debian.

WarVOX requires PostgreSQL 9.1 or newer with the "contrib" package installed for integer array support.

To get started, install the OS-level dependencies:

	$ sudo apt-get install gnuplot lame build-essential libssl-dev libcurl4-openssl-dev \ 
	  postgresql postgresql-contrib postgresql-common git-core curl libpq-dev sox

Install RVM to obtain Ruby 2.2.5 or later

	$ \curl -L https://get.rvm.io | bash -s stable --autolibs=3 --rails

After RVM is installed you need to run the rvm script provided

	$ source /usr/local/rvm/scripts/rvm

In case you have not installed Ruby 2.2.5 or later by now, do so using RVM.

	$ rvm install ruby-2.2.5
        
Clone this repository to the location you want to install WarVOX:

	$ git clone git://github.com/rapid7/warvox.git /opt/warvox

Configure WarVOX:

	$ cd /opt/warvox
	$ bundle install
	$ make

Verify your installation:

	$ bin/verify_install.rb

Configure the PostgreSQL account for WarVOX:

	$ sudo su - postgres
	$ createuser -s warvox
	$ createdb warvox -O warvox
	$ psql
	psql> alter user warvox with password 'randompass';
	psql> exit
	$ exit

Copy the example database configuration to database.yml:

	$ cp config/database.yml.example config/database.yml

Copy the example secrets configuration to secrets.yml:

	$ cp config/secrets.yml.example config/secrets.yml

Modify config/database.yml to include the password set previously

Initialize the WarVOX database:

	$ make database

Add an admin account to WarVOX

	$ bin/adduser admin randompass

Start the WarVOX daemons:

	$ bin/warvox.rb 

or to bind WarVox to all interfaces:

	$ bin/warvox.rb --address 0.0.0.0

Access the web interface at http://127.0.0.1:7777/

At this point you can configure a new IAX2 provider, create a project, and start making calls.


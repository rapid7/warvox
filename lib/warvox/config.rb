module WarVOX
module Config
	require 'yaml'
	
	def self.authentication_creds
		user = nil
		pass = nil
		info = YAML.load_file(WarVOX::Conf)
		if( info and
			info['authentication'] and
			info['authentication']['user'] and
			info['authentication']['pass']
		  )
			user = info['authentication']['user']
			pass = info['authentication']['pass']
		end		
		[user,pass]
	end
	
	def self.authenticate(user,pass)
		wuser,wpass = authentication_creds
		(wuser == user and wpass == pass) ? true : false	
	end
	
	def self.tool_path(name)
		info = YAML.load_file(WarVOX::Conf)
		return nil if not info
		return nil if not info['tools']
		return nil if not info['tools'][name]
		find_full_path(
			info['tools'][name].gsub('%BASE%', WarVOX::Base)
		)
	end
	
	def self.data_path
		info = YAML.load_file(WarVOX::Conf)
		return nil if not info
		return nil if not info['data_path']
		File.expand_path(info['data_path'].gsub('%BASE%', WarVOX::Base))
	end

	def self.analysis_threads
		info = YAML.load_file(WarVOX::Conf)
		return 1 if not info
		return 1 if not info['analysis_threads']
		[ info['analysis_threads'].to_i, 1 ].max
	end
	
	def self.blacklist_path
		info = YAML.load_file(WarVOX::Conf)
		return nil if not info
		return nil if not info['blacklist']
		File.expand_path(info['blacklist'].gsub('%BASE%', WarVOX::Base))
	end

	def self.blacklist_load
		path = blacklist_path
		return if not path
		data = File.read(path, File.size(path))
		sigs = []
		
		File.open(path, 'r') do |fd|
			lno = 0
			fd.each_line do |line|
				lno += 1
				next if line =~ /^#/
				next if line =~ /^\s+$/
				line.strip!
				sigs << [lno, line]
			end
			sigs
		end
		
	end

	def self.signatures_path
		info = YAML.load_file(WarVOX::Conf)
		return nil if not info
		return nil if not info['signatures']
		File.expand_path(info['signatures'].gsub('%BASE%', WarVOX::Base))
	end
	
	def self.signatures_load
		path = signatures_path
		sigs = []
		return sigs if not path

		Dir.new(path).entries.sort{ |a,b| 
			a.to_i <=> b.to_i 
		}.map{ |ent| 
			File.join(path, ent) 
		}.each do |ent|
			sigs << ent if File.file?(ent)
		end
		
		sigs
	end
	
	# This method searches the PATH environment variable for
	# a fully qualified path to the supplied file name.
	# Stolen from Rex
	def self.find_full_path(file_name)
		
		# Return absolute paths unmodified
		if(file_name[0,1] == ::File::SEPARATOR)
			return file_name
		end
		
		path = ENV['PATH']
		if (path)
			path.split(::File::PATH_SEPARATOR).each { |base|
				begin
					path = base + ::File::SEPARATOR + file_name
					if (::File::Stat.new(path))
						return path
					end
				rescue
				end
			}
		end
		return nil
	end
	
	# This method prevents two installations of WarVOX from using the same
	# rails session key. The first time this method is called, it generates
	# a new key and stores it in the rails directory, afterwards this key
	# will be used every time.
	def self.load_session_key
		kfile = File.join(WarVOX::Base, 'web', 'config', 'session.key')
		if(not File.exists?(kfile))
			# XXX: assume /dev/urandom exists
			kdata = File.read('/dev/urandom', 64).unpack("H*")[0]

			# Create the new session key file
			fd = File.new(kfile, 'w')
			
			# Make this file mode 0600
			File.chmod(0600, kfile)
			
			# Write it and close
			fd.write(kdata)
			fd.close
			return kdata
		end
		File.read(kfile)
	end
		

end
end

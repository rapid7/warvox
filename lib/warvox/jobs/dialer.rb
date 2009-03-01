module WarVOX
module Jobs
class Dialer < Base 

	require 'fileutils'
	
	def type
		'dialer'
	end
	
	def initialize(job_id)
		@name    = job_id
		model    = get_job
		@range   = model.range
		@seconds = model.seconds
		@lines   = model.lines		
		@nums    = shuffle_a(WarVOX::Phone.crack_mask(@range))
		@cid     = '8005551212' # XXX: Read from job
	end

	#
	# Performs a Fisher-Yates shuffle on an array
	#
	def shuffle_a(arr)
		len = arr.length
		max = len - 1
		cyc = [* (0..max) ]
		for d in cyc
			e = rand(d+1)
			next if e == d
			f = arr[d];
			g = arr[e];
			arr[d] = g;
			arr[e] = f;
		end
		return arr
	end

	def get_providers
		res = []

		::Provider.find(:all).each do |prov|
			info = {
				:name  => prov.name,
				:id    => prov.id,
				:port  => prov.port,
				:host  => prov.host,
				:user  => prov.user,
				:pass  => prov.pass,
				:lines => prov.lines
			}
			1.upto(prov.lines) {|i| res.push(info) }
		end
		
		shuffle_a(res)
	end
	
	def get_job
		::DialJob.find(@name)
	end
	
	def start
		begin
		
		model = get_job
		model.status = 'active'
		model.started_at = Time.now
		model.save
		
		start_dialing()
		
		stop()
		
		rescue ::Exception => e
			$stderr.puts "Exception in the job queue: #{$e.class} #{e} #{e.backtrace}"
		end
	end
	
	def stop
		@status = 'completed'
		model = get_job
		model.status = 'completed'
		model.completed_at = Time.now
		model.save
	end
	
	def start_dialing
		dest = File.join(WarVOX::Config.data_path, "#{@name}-#{@range}")
		FileUtils.mkdir_p(dest)
	
		@nums_total = @nums.length
		while(@nums.length > 0)
			@calls    = []
			@provs    = get_providers
			tasks     = []
			max_tasks = [@provs.length, @lines].min
			
			1.upto(max_tasks) do
				tasks << Thread.new do
					
					Thread.current.kill if @nums.length == 0
					Thread.current.kill if @provs.length == 0
		
					num  = @nums.shift
					prov = @provs.shift
					
					Thread.current.kill if not num
					Thread.current.kill if not prov
					
					out = File.join(dest, num+".raw")

					begin
					# Execute and read the output
					busy = 0
					ring = 0
					fail = 1
					byte = 0
					path = ''
					
					IO.popen(
						[
							WarVOX::Config.tool_path('iaxrecord'),
							prov[:host],
							prov[:user],
							prov[:pass],
							@cid,
							out,
							num,
							@seconds
						].map{|i| 
							"'" + i.to_s.gsub("'",'') +"'" 
					}.join(" ")).each_line do |line|
						$stderr.puts "DEBUG: #{line.strip}"
						if(line =~ /^COMPLETED/)
							line.split(/\s+/).map{|b| b.split('=', 2) }.each do |info|
								busy = info[1].to_i if info[0] == 'BUSY'
								fail = info[1].to_i if info[0] == 'FAIL'
								ring = info[1].to_i if info[0] == 'RINGTIME'
								byte = info[1].to_i if info[0] == 'BYTES'	
								path = info[1]      if info[0] == 'FILE'
							end
						end
					end
					
					res = ::DialResult.new
					res.number = num
					res.dial_job_id = @name
					res.provider_id = prov[:id]
					res.completed = (fail == 0) ? true : false
					res.busy = (busy == 1) ? true : false
					res.seconds = (byte / 16000)  # 8khz @ 16-bit
					res.ringtime = ring
					res.processed = false
					res.created_at = Time.now
					res.updated_at = Time.now
					
					if(File.exists?(out))
						system("gzip -9 #{out}")
						res.rawfile = out + ".gz"
					end
					
					@calls << res
					
					rescue ::Exception => e
						$stderr.puts "ERROR: #{e.class} #{e} #{e.backtrace} #{num} #{prov.inspect}"
					end
				end
	
				# END NEW THREAD
			end
			# END SPAWN THREADS
			tasks.map{|t| t.join if t}
			
			# Save data to the database
			begin
			
				# Iterate through the results
				@calls.each do |r|
					tries = 0
					begin
						r.save
					rescue ::Exception => e
						$stderr.puts "ERROR: #{r.inspect} #{e.class} #{e}"
						tries += 1
						Kernel.select(nil, nil, nil, 0.25 * (rand(8)+1))
						retry if tries < 5
					end
				end
				
				# Update the progress bar
				model = get_job
				model.progress = ((@nums_total - @nums.length) / @nums_total.to_f) * 100
				model.save

			rescue ::SQLite3::BusyException => e
				$stderr.puts "ERROR: Database lock hit trying to save, retrying"
				retry
			end
		end
		
		# ALL DONE
	end

end
end
end

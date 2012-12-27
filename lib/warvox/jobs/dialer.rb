module WarVOX
module Jobs
class Dialer < Base

	require 'fileutils'

	def type
		'dialer'
	end

	def initialize(job_id)
		@name    = job_id
		@job     = get_job
		@range   = @job.range
		@seconds = @job.seconds
		@lines   = @job.lines
		@nums    = shuffle_a(WarVOX::Phone.crack_mask(@range))

		# CallerID modes (SELF or a mask)
		@cid_self = @job.cid_mask == 'SELF'
		if(not @cid_self)
			@cid_range = WarVOX::Phone.crack_mask(@job.cid_mask)
		end
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

		::Provider.find_all_by_enabled(true).each do |prov|
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
		db_save(model)

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
		db_save(model)
	end

	def start_dialing
		dest = File.join(WarVOX::Config.data_path, @name.to_s)
		FileUtils.mkdir_p(dest)

		# Scrub all numbers matching the blacklist
		list = WarVOX::Config.blacklist_load
		list.each do |b|
			lno,reg = b
			@nums.each do |num|
				if(num =~ /#{reg}/)
					$stderr.puts "DEBUG: Skipping #{num} due to blacklist (line: #{lno})"
					@nums.delete(num)
				end
			end
		end

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
					cid  = @cid_self ? num : @cid_range[ rand(@cid_range.length) ]

					IO.popen(
						[
							WarVOX::Config.tool_path('iaxrecord'),
							"-s",
							prov[:host],
							"-u",
							prov[:user],
							"-p",
							prov[:pass],
							"-c",
							cid,
							"-o",
							out,
							"-n",
							num,
							"-l",
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
					res.cid = cid
					res.dial_job_id = @name
					res.provider_id = prov[:id]
					res.completed = (fail == 0) ? true : false
					res.busy = (busy == 1) ? true : false
					res.seconds = (byte / 16000)  # 8khz @ 16-bit
					res.ringtime = ring
					res.processed = false

					if(File.exists?(out))
						File.open(out, "rb") do |fd|
							res.audio = fd.read(fd.stat.size)
						end
						File.unlink(out)
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

			# Iterate through the results
			@calls.each do |r|
				db_save(r)
			end

			# Update the progress bar
			model = get_job
			model.progress = ((@nums_total - @nums.length) / @nums_total.to_f) * 100
			db_save(model)

			clear_zombies()
		end

		# ALL DONE
	end

end
end
end

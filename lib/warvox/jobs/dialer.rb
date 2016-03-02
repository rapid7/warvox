module WarVOX
module Jobs
class Dialer < Base

  require 'fileutils'

  def type
    'dialer'
  end

  def initialize(job_id, conf)
    @job_id  = job_id
    @conf    = conf
    @range   = @conf[:range]
    @seconds = @conf[:seconds]
    @lines   = @conf[:lines]
    @nums    = shuffle_a(WarVOX::Phone.crack_mask(@range))

    @tasks   = []
    @provs   = get_providers

    # CallerID modes (SELF or a mask)
    @cid_self = @conf[:cid_mask] == 'SELF'
    if(not @cid_self)
      @cid_range = WarVOX::Phone.crack_mask(@conf[:cid_mask])
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

    ::ActiveRecord::Base.connection_pool.with_connection {
      ::Provider.where(:enabled => true).all.each do |prov|
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
    }

    shuffle_a(res)
  end


  def stop
    @nums = []
    @tasks.each do |t|
      t.kill rescue nil
    end
    @tasks = []
  end

  def start
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

    last_update = Time.now
    @nums_total = @nums.length

    max_tasks = [@provs.length, @lines].min

    while(@nums.length > 0)
      while( @tasks.length < max_tasks ) do
        tnum  = @nums.shift
        break unless tnum

        tprov = allocate_provider

        @tasks << Thread.new(tnum,tprov) do |num,prov|

          out_fd = Tempfile.new("rawfile")
          out    = out_fd.path

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

          ::ActiveRecord::Base.connection_pool.with_connection do
            job = Job.find(@job_id)
            if not job
              raise RuntimeError, "The parent job is not available"
            end

            res = ::Call.new
            res.number        = num
            res.job_id        = job.id
            res.project_id    = job.project_id
            res.provider_id   = prov[:id]
            res.answered      = (fail == 0) ? true : false
            res.busy          = (busy == 1) ? true : false
            res.audio_length = (byte / 16000)  # 8khz @ 16-bit
            res.ring_length  = ring
            res.caller_id     = cid

            res.save

            if(File.exists?(out))
              File.open(out, "rb") do |fd|
                med = res.media
                med.audio = fd.read(fd.stat.size)
                med.save
              end
            end

            out_fd.close
            ::FileUtils.rm_f(out)
          end

          rescue ::Exception => e
            $stderr.puts "ERROR: #{e.class} #{e} #{e.backtrace} #{num} #{prov.inspect}"
          end
        end

        # END NEW THREAD
      end
      # END SPAWN THREADS

      clear_stale_tasks

      # Update progress every 10 seconds or so
      if Time.now.to_f - last_update.to_f > 10
        update_progress(((@nums_total - @nums.length) / @nums_total.to_f) * 100)
        last_update = Time.now.to_f
      end

      clear_zombies()
    end

    while @tasks.length > 0
      clear_stale_tasks
    end

    # ALL DONE
  end

  def clear_stale_tasks
    # Remove dead threads from the task list
    @tasks = @tasks.select{ |x| x.status }
    IO.select(nil, nil, nil, 0.25)
  end

  def update_progress(pct)
    ::ActiveRecord::Base.connection_pool.with_connection {
      Job.where(id: @job_id).update_all(progress: pct)
    }
  end

  def allocate_provider
    @prov_idx ||= 0
    prov = @provs[ @prov_idx % @provs.length ]
    @prov_idx  += 1
    prov
  end

end
end
end

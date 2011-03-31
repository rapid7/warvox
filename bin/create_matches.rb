#!/usr/bin/env ruby

#
# Given the path to a signature file, determine the closests matching signatures
# within the same directory, creating a .match file.
#


def is_bad_sig?(sig)
	return true if sig == 0
	false
end

def load_signature(data)
	data.split("\n").map { |line|
		line.strip.to_i
	}.reject {|sig| is_bad_sig?(sig) }
end

inp = ARGV.shift || exit(1)
ind = ARGV.shift
dir = File.expand_path(inp) + "/"
set = {}

d = Dir.new(dir)
d.entries.each do |ent|
	next if ent !~ /\.sigs$/
	name,trash = ent.split('.', 2)
	data       = File.read(File.join(dir, ent))
	set[name]  = load_signature(data)
	
	if set.keys.length % 500 == 0
		puts "[*] Loaded #{set.keys.length} signatures..."		
	end
end
d.close

puts "[*] Finished loading #{set.keys.length} signatures..."

max   = 10
cnt   = 0
stime = Time.now.to_f

targs = ind ? [ind] : set.keys.sort

while targs.length > 0
	jobs = []

	while jobs.length < max
		targ = targs.shift
		break if not targ
		pid = fork
		
		if pid
			jobs << pid
			next
		end
	
		mine = targ
		msig = set[targ]
	
		exit(0) if msig.length == 0
		
		res  = []
		set.each_pair do |n,sig|
			next if n == mine
			hits = (msig & sig).length
			res << [ ( hits / msig.length.to_f ) * 100.0, hits, n ]
		end

		File.open(File.join(dir, mine + ".matches"), "w") do |fd|
			res.sort{|a,b| b[0] <=> a[0] }.each do |r|
				fd.puts "#{"%.2f" % r[0]}\t#{r[2]}"
			end
		end
	
		exit(0)
	end
	jobs.each {|j| Process.waitpid(j) }
	cnt += jobs.length
	puts "[*] Processed #{cnt}/#{set.keys.length} in #{Time.now.to_f - stime} seconds"	
end

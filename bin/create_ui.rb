#!/usr/bin/env ruby
###################

#
# Load the library path
# 
base = __FILE__
while File.symlink?(base)
	base = File.expand_path(File.readlink(base), File.dirname(base))
end
$:.unshift(File.join(File.expand_path(File.dirname(base)), '..', 'lib'))
require 'warvox'

#
# Script
#
require "fileutils"
require "tempfile"

def usage
	"#{$0} src/ dst/"
	exit(0)
end

src = ARGV.shift || usage
dst = ARGV.shift || usage


FileUtils.mkdir_p(dst)
FileUtils.copy(File.join(base, "ui", "player.swf"), File.join(dst, "player.swf"))
FileUtils.copy(File.join(base, "ui", "styles.css"), File.join(dst, "styles.css"))

calls = []
dir = Dir.new(src)
dir.entries.sort.each do |ent|

	path = File.join(src, ent)
	next if ent !~ /(.*)\.raw.gz$/m
	num = $1

	calls << num
	if(File.exists?(File.join(dst, "#{num}.html")))
		puts "Skipping #{num}..."
		next
	end

	puts "Processing #{num}..."
	
	# Decompress the audio file
	rawfile = Tempfile.new("rawfile")
	system("zcat #{path} > #{rawfile.path}")

	# Generate data samples
	system("ruby #{base}/bin/sampler.rb #{rawfile.path} > #{dst}/#{num}.dat")
	
	# Plot samples to a graph
	plotter = Tempfile.new("gnuplot")
	
	
	plotter.puts("set ylabel \"Frequency\"")
	plotter.puts("set xlabel \"Time\"")
	
	plotter.puts("set terminal png medium size 640,480 transparent")
	plotter.puts("set output \"#{dst}/#{num}_big.png\"")
	plotter.puts("plot \"#{dst}/#{num}.dat\" using 1:2 title \"#{num}\" with lines")
		
	plotter.puts("set terminal png small size 160,120 transparent")
	plotter.puts("set format x ''")
	plotter.puts("set format y ''")	
	plotter.puts("set output \"#{dst}/#{num}.png\"")
	plotter.puts("plot \"#{dst}/#{num}.dat\" using 1:2 title \"#{num}\" with lines")

	plotter.flush
	system("gnuplot #{plotter.path}")
	File.unlink(plotter.path)
	File.unlink("#{dst}/#{num}.dat")
	plotter.close
	
	# Detect the carrier
	carrier = `ruby #{base}/bin/detect_carrier.rb #{rawfile.path}`
	eout = File.new(File.join(dst, "#{num}.info"), "w")
	eout.write("#{num} #{carrier}")
	eout.close
	

	# Generate a MP3 audio file
	system("sox -s -w -r 8000 -t raw -c 1 #{rawfile.path} #{dst}/#{num}.wav")
	system("lame #{dst}/#{num}.wav #{dst}/#{num}.mp3 >/dev/null 2>&1")
	File.unlink("#{dst}/#{num}.wav")
	File.unlink(rawfile.path)
	rawfile.close
	
	# Generate the HTML
	html = %Q{
<html>
	<head>
		<title>Analysis of #{num}</title>
		<link rel="stylesheet" href="styles.css" type="text/css" />
	</head>
<body>

<center>

<h1>#{num}</h1>
<img src="#{num}_big.png"><br/><br/>
<object class="playerpreview" type="application/x-shockwave-flash" data="player.swf" width="200" height="20">
    <param name="movie" value="player.swf" />
    <param name="FlashVars" value="mp3=#{num}.mp3&amp;showstop=1&amp;showvolume=1&amp;bgcolor1=189ca8&amp;bgcolor2=085c68" />
</object>

<p>#{num} - #{carrier}</p>
<p><a href="index.html">&lt;&lt;&lt; Back</a></p>
	
</center>
</body>
</html>	
	}
	
	eout = File.new(File.join(dst, "#{num}.html"), "w")
	eout.write(html)
	eout.close
	
#	break if calls.length > 10
end

# Create the final output web page
eout = File.new(File.join(dst, "index.html"), "w")

html = %Q{
<html>
	<head>
		<title>Call Analysis</title>
		<link rel="stylesheet" href="styles.css" type="text/css" />
	</head>
<body>
<center>

<h1>Results for #{calls.length} Calls</h1>
<table align="center" border=0 cellspacing=0 cellpadding=6>
}

max = 6
cnt = 0
calls.sort.each do |num|
	if(cnt == max)
		html << %Q{</tr>\n}
		cnt = 0
	end
	
	if(cnt == 0)
		html << %Q{<tr>}
	end
		
	live = ( File.read(File.join(dst, "#{num}.info")) =~ /CARRIER/ ) ? "carrier" : "voice"
	html << %Q{<td class="#{live}"><a href="#{num}.html"><img src="#{num}.png" border=0></a></td>}
	cnt += 1
end

while(cnt < max)
	html << "<td>&nbsp;</td>"
	cnt += 1
end
html << "</tr>\n"

html << %Q{
</table>
</center>
</body>
</html>	
}


eout.write(html)
eout.close

puts "Completed"

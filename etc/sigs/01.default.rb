#
# WarVOX Default Signatures
#

#
# These signatures are used first and catch the majority of common
# systems. If you want to force a different type of detection, add
# your signatures to a file starting with "00." and place it in
# this directory. Signature files are processed numerically from
# lowest to highest (like RC scripts)
#


#
# Initialize some local variables out of data
#
freq = data[:freq]
fcnt = data[:fcnt]
maxf = data[:maxf]

#
# Look for silence by checking for a strong frequency in each sample
#
scnt = 0
ecnt = 0
=begin
freq.each do |fsec|
	scnt += 1
	if(fsec.length == 0)
		ecnt += 1
		next
	end
	sump = 0
	fsec.map {|x| sump += x[1] }
	savg = sump / fsec.length
	ecnt += 1 if (savg < 100)
end
=end

# Store these into data for use later on
data[:scnt] = scnt
data[:ecnt] = ecnt

#
# Look for modems by detecting a 2100hz answer + 2250hz tone
#
if( (fcnt[2100] > 1.0 or fcnt[2230] > 1.0) and fcnt[2250] > 0.5)
	@line_type = 'modem'
	raise Completed
end

#
# Look for modems by detecting a peak frequency of 2250hz
#
if(fcnt[2100] > 1.0 and (maxf > 2245.0 and maxf < 2255.0))
	@line_type = 'modem'
	raise Completed
end

#
# Look for modems by detecting a peak frequency of 3000hz
#
if(fcnt[2100] > 1.0 and (maxf > 2995.0 and maxf < 3005.0))
	@line_type = 'modem'
	raise Completed
end

#
# Look for faxes by checking for a handful of tones (min two)
#
fax_sum = 0
[
	fcnt[1625], fcnt[1660], fcnt[1825], fcnt[2100],
	fcnt[600],  fcnt[1855], fcnt[1100], fcnt[2250],
	fcnt[2230], fcnt[2220], fcnt[1800], fcnt[2095],
	fcnt[2105]
].map{|x| fax_sum += [x,1.0].min }
if(fax_sum >= 2.0)
	@line_type = 'fax'
	raise Completed
end

#
# Dial tone detection (440hz + 350hz)
#
if(fcnt[440] > 1.0 and fcnt[350] > 1.0)
	@line_type = 'dialtone'
	raise Completed
end

#
# To use additional signatures, add new scripts to this directory
# named XX.myscript.rb, where XX is a two digit number less than
# 99 and greater than 01.
#
#


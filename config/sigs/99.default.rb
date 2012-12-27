#
# WarVOX Fallback Signatures
#
#

#
# Initialize some local variables out of data
#
freq = data[:freq]
fcnt = data[:fcnt]
maxf = data[:maxf]
ecnt = data[:ecnt]
scnt = data[:scnt]


# Look for voice mail by detecting the 1000hz BEEP
# If the call length was too short to catch the beep,
# this signature can fail. For non-US numbers, the beep
# is often a different frequency entirely.
if(fcnt[1000] >= 1.0)
	@line_type = 'voicemail'
	raise Completed
end

# Look for voicemail by detecting a peak frequency of
# 1000hz. Not as accurate, but thats why this is in
# the fallback script.
if(maxf > 995 and maxf < 1005)
	@line_type = 'voicemail'
	raise Completed
end

=begin

#
# Look for silence by checking the frequency signature
#
if(freq.map{|f| f.length}.inject(:+) == 0)
	@line_type = 'silence'
	raise Completed
end


if(ecnt == scnt)
	@line_type = 'silence'
	raise Completed
end
=end

#
# Fall back to 'voice' if nothing else has been matched
# This should be the last signature file processed
#

@line_type = 'voice'


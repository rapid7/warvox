#
# WarVOX Default Signatures
#

#
# Variables:
#	pks  = peak frequencies
#	ppz  = top 10 frequencies per sample
#	flow = flow signature
#

#
# These signatures are used first and catch the majority of common
# systems. If you want to force a different type of detection, add
# your signatures to a file starting with "00." and place it in
# this directory. Signature files are processed numerically from
# lowest to highest (like RC scripts)
#


#
# Look for silence by checking for any significant noise
#
if(flow.split(/\s+/).grep(/^H,/).length == 0)
	line_type = 'silence'
	break
end


#
# Look for modems by detecting a peak 2250hz tone
#
f_2250 = 0
pks.each{|f| f_2250 += 1 if(f[0] > 2240 and f[0] < 2260) }
if(f_2250 > 2)
	line_type = 'modem'
	break				
end


#
# Most faxes have at least two of the following tones
# This can false positive if the modem signature above
# is removed.
#
f_1625 = f_1660 = f_1825 = f_2100 = false
pks.each do |f|
	f_1625 = true if(f[0] > 1620 and f[0] < 1630)
	f_1660 = true if(f[0] > 1655 and f[0] < 1665)
	f_1825 = true if(f[0] > 1820 and f[0] < 1830)
	f_2100 = true if(f[0] > 2090 and f[0] < 2110)										
end
if([ f_1625, f_1660, f_1825, f_2100 ].grep(true).length >= 2)
	line_type = 'fax'
	break
end


#
# Dial tone detection (more precise to use pkz over pks)
# Look for a combination of 440hz + 350hz signals
#
f_440 = 0
f_350 = 0
pkz.each do |fb|
	fb.each do |f|
		f_440  += 0.1 if (f[0] > 437 and f[0] < 444)	
		f_350  += 0.1 if (f[0] > 345 and f[0] < 355)
	end
end
if(f_440 > 1.0 and f_350 > 1.0)
	line_type = 'dialtone'
	break
end


#
# Look for voice mail by detecting the 1000hz BEEP
# If the call length was too short to catch the beep,
# this signature can fail. For non-US numbers, the beep
# is often a different frequency entirely.
#
f_1000 = 0
pks.each{|f| f_1000 += 1 if(f[0] > 990 and f[0] < 1010) }
if(f_1000 > 0)
	line_type = 'voicemail'
	break				
end


#
# To use additional signatures, add new scripts to this directory
# named XX.myscript.rb, where XX is a two digit number less than
# 99 and greater than 01.
#
#

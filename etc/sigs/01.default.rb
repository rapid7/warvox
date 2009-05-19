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
# Summarize detection of a whole bunch of frequencies (used below)
#
f_2250 = 0
f_440  = f_350  = 0
f_1625 = f_1660 = f_1825 = f_2100 = f_1100 = 0
f_600  = f_1855 = 0

pkz.each do |fb|
	fb.each do |f|
		f_2250 += 0.1 if(f[0] > 2240 and f[0] < 2260)
		f_440  += 0.1 if(f[0] > 437 and f[0] < 444)	
		f_350  += 0.1 if(f[0] > 345 and f[0] < 355)	
		f_1625 += 0.1 if(f[0] > 1620 and f[0] < 1630)
		f_1660 += 0.1 if(f[0] > 1655 and f[0] < 1665)
		f_1825 += 0.1 if(f[0] > 1820 and f[0] < 1830)
		f_1855 += 0.1 if(f[0] > 1850 and f[0] < 1860)
		f_2100 += 0.1 if(f[0] > 2090 and f[0] < 2110)
		f_1100 += 0.1 if(f[0] > 1090 and f[0] < 1110)
		f_600  += 0.1 if(f[0] > 595 and  f[0] < 605)									
	end
end

#
# Look for modems by detecting a 2250hz tone
#
if(f_2250 > 1.0)
	line_type = 'modem'
	break				
end

#
# Look for faxes by checking for a handful of tones (min two)
#
fax_sum = 0
[ f_1625, f_1660, f_1825, f_2100, f_600, f_1855, f_1100].map{|x| fax_sum += [x,1.0].min }
if(fax_sum >= 2.0)
	line_type = 'fax'
	break
end

#
# Dial tone detection (440hz + 350hz)
#
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

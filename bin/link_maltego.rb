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
require 'rexml/document'

#
# Script
#

#
# http://ctas.paterva.com/view/Specification
#

def xml_results_empty
	root = REXML::Element.new('MaltegoMessage')
	xml2 = root.add_element('MaltegoTransformResponseMessage')
	xml2.add_element('Entities')
	root
end

def xml_results_matches(res)
	root = REXML::Element.new('MaltegoMessage')
	xml2 = root.add_element('MaltegoTransformResponseMessage')
	xml3 = xml2.add_element('Entities')
	
	res.each_key do |k|
		num_area = k[0,3]
		num_city = k[3,3]
		num_last = k[6,4]
	
		num = num_area + " " + num_city + " " + num_last
		
		val = REXML::Element.new('Value')
		val.add_text(num)

		adf = REXML::Element.new('AdditionalFields')
		
			adf_area = REXML::Element.new('Field')
			adf_area.add_attribute('Name', 'areacode')
			adf_area.add_text( REXML::Text.new( num_area.to_s ) )
			adf << adf_area

			adf_city = REXML::Element.new('Field')
			adf_city.add_attribute('Name', 'citycode')
			adf_city.add_text( REXML::Text.new( num_city.to_s ) )
			adf << adf_city

			adf_last = REXML::Element.new('Field')
			adf_last.add_attribute('Name', 'lastnumbers')
			adf_last.add_text( REXML::Text.new( num_last.to_s ) )
			adf << adf_last

			adf_info = REXML::Element.new('Field')
			adf_info.add_attribute('Name', 'additional')
			adf_info.add_text( REXML::Text.new( "Sig: " + res[k][:sig].map{|x| "#{x[0]},#{x[1]},#{x[2]}"}.join(" ") ) )
			adf << adf_info
									

		wgt = REXML::Element.new('Weight')
		wgt.add_text(  REXML::Text.new( [res[k][:len] * 10, 100].min.to_s  ) )
		
		ent = REXML::Element.new('Entity')
		ent.add_attribute('Type', 'PhoneNumber')

		ent << val
		ent << wgt
		ent << adf
		
		xml3 << ent
	end
	root
end


# Only report each percentage once
@progress_done = {}

def report_progress(pct)
	return if @progress_done[pct]
	$stderr.puts "%#{pct}"
	$stderr.flush
	@progress_done[pct] = true
end

def usage
	$stderr.puts "#{$0} [target] [params]"
	exit
end

#
# Parse input
#

params = {}
target = ARGV.shift || usage()
(ARGV.shift || usage()).split('#').each do |param|
	k,v = param.split('=', 2)
	params[k] = v
end

# XXX: Problematic right now
# target_number = params['areacode'] + params['citycode'] + params['lastnumbers']

target_number = target.scan(/\d+/).join
if(target_number.length != 10)
	$stderr.puts "D: Only 10 digit US numbers are currently supported"
	$stdout.puts xml_results_empty().to_s
	exit	
end


#
# Search database
#

carriers = {}

data_root = File.join(File.dirname(base), '..', 'data')
wdb       = WarVOX::DB.new(nil)

Dir.new(data_root).entries.grep(/\.db$/).each do |db|
	$stderr.puts "D: Loading #{db}..."
	wdb.import(File.join(data_root, db))
end

# No matching number
if(not wdb[target_number])
	$stderr.puts "D: Target #{target_number} (#{target}) is not in the WarVOX database"
	$stdout.puts xml_results_empty().to_s
	exit
end

found = {}
cnt = 0
wdb.each_key do |n|
	cnt += 1
	
	report_progress(((cnt / wdb.keys.length.to_f) * 100).to_i.to_s)

	next if target_number == n
	begin
		res = wdb.find_sig(target_number, n, { :fuzz => 100 })
	rescue ::WarVOX::DB::Error
	end
	next if not res
	next if res[:len] < 5
	found[n] = res
end

$stdout.puts xml_results_matches(found).to_s

#!/usr/bin/ruby

base = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
$:.unshift(File.join(File.dirname(base)))

require 'test/unit'
require 'kissfft'
require 'pp'

#
# Simple unit test
#

class KissFFT::UnitTest < Test::Unit::TestCase
	def test_version
		assert_equal(String, KissFFT.version.class)
		puts "KissFFT version: #{KissFFT.version}"
	end		
	def test_fftr
		data = ( [*(1..100)] * 1000).flatten
		
		r = KissFFT.fftr(8192, 8000, 1, data)
		r.each do |x|
			mf = 0
			mp = 0
			x.each do |o|
				if(o[1] > mp)
					mp = o[1]
					mf = o[0]
				end
			end
			puts "#{mf} @ #{mp}"
		end
	end					
end

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
require 'csv'

ENV['RAILS_ENV'] ||= 'production'
$:.unshift(File.join(File.expand_path(File.dirname(base)), '..'))

def usage
  $stderr.puts "Usage: #{$0} [Job ID] <Type>"
  exit
end

#
# Script
#

project_id = ARGV.shift
line_type  = ARGV.shift

if(project_id and project_id == "-h")
  usage()
end

if project_id.to_i == 0
  usage()
end

require 'config/boot'
require 'config/environment'

if(not project_id)
  $stderr.puts "Listing all projects"
  $stderr.puts "===================="
  Project.all.each do |j|
    puts "#{j.id}\t#{j.name}\t#{j.created_at}"
  end
  exit
end

fields = %W{ number line_type caller_id answered busy audio_length ring_length peak_freq }
begin
  $stdout.puts fields.to_csv
  cond = { :project_id => project_id.to_i }
  if line_type
    cond[:line_type] = line_type.downcase
  end
  Call.where(cond).order(number: :asc).each do |r|
    out = []
    fields.each do |f|
      out << r[f].to_s
    end
    $stdout.puts out.to_csv
  end
end

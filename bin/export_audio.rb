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
require 'fileutils'
require 'yaml'

ENV['RAILS_ENV'] ||= 'production'
$:.unshift(File.join(File.expand_path(File.dirname(base)), '..'))

def usage
  $stderr.puts "Usage: #{$0} [Output Dir] [Project ID] <Line Type>"
  exit
end

#
# Script
#

output     = ARGV.shift
project_id = ARGV.shift
line_type  = ARGV.shift

if(output and output == "-h") or (! output)
  usage()
end

require 'config/boot'
require 'config/environment'

if project_id.to_i == 0
  $stderr.puts "Listing all projects"
  $stderr.puts "===================="
  Project.all.each do |j|
    puts "#{j.id}\t#{j.name}\t#{j.created_at}"
  end
  exit
end

FileUtils.mkdir_p(output)

begin
  cond = { :project_id => project_id.to_i, :answered => true, :busy => false }
  if line_type
    cond[:line_type] = line_type.downcase
  end

  Call.where(cond).order(number: :asc).each do |r|
    m = r.media
    if m and m.audio

      ::File.open(File.join(output, "#{r.number}.raw"), "wb") do |fd|
        fd.write(m.audio)
      end

      ::File.open(File.join(output, "#{r.number}.yml"), "wb") do |fd|
        fd.write(r.to_yaml)
      end

      if m.mp3
        ::File.open(File.join(output, "#{r.number}.mp3"), "wb") do |fd|
          fd.write(m.mp3)
        end
      end

      if m.png_big
        ::File.open(File.join(output, "#{r.number}_wave.png"), "wb") do |fd|
          fd.write(m.png_big)
        end
      end

      if m.png_big_freq
        ::File.open(File.join(output, "#{r.number}_freq.png"), "wb") do |fd|
          fd.write(m.png_big_freq)
        end
      end

      $stderr.puts "[*] Exported #{r.number}..."

    end
  end
end

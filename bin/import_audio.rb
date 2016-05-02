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


ENV['RAILS_ENV'] ||= 'production'

$:.unshift(File.join(File.expand_path(File.dirname(base)), '..'))

def usage
  $stderr.puts "Usage: #{$0} [Input Directory] <Project ID> <Provider ID>"
  exit(1)
end

#
# Script
#

dir = ARGV.shift() || usage()
if (dir and dir =="-h") or (! dir)
  usage()
end

require 'config/boot'
require 'config/environment'

project_id  = ARGV.shift
provider_id = ARGV.shift

todo = Dir["#{dir}/**/*.{raw,wav}"].to_a

if todo.empty?
  $stderr.puts "Error: No raw audio files found within #{dir}"
  exit(1)
end

project  = nil
provider = nil

if project_id
  project = Project.where(:id => project_id).first
  unless project
    $stderr.puts "Error: Specified Project ID not found"
    exit(1)
  end
end

if provider_id
  provider = Provider.where(:id => provider_id).first
  unless provider
    $stderr.puts "Error: Specified Provider ID not found"
    exit(1)
  end
end

unless project
  project = Project.create(
    :name       => "Import from #{dir} at #{Time.now.utc.to_s}",
    :created_by => "importer"
  )
end

provider = Provider.first
unless provider
  provider = Provider.create(
    :name    => 'Import Provider',
    :host    => 'localhost',
    :port    => 4369,
    :user    => "null",
    :pass    => "null",
    :lines   => 1,
    :enabled => false
  )
end


job = Job.new
job.project_id   = project.id
job.locked_by    = "importer"
job.locked_at    = Time.now.utc
job.started_at   = Time.now.utc
job.created_by   = "importer"
job.task         = "import"
job.args         = Marshal.dump({ :directory => dir, :project_id => project.id, :provider_id => provider.id })
job.status       = "running"
job.save!

pct  = 0
cnt  = 0

todo.each do |rfile|
  num, ext = File.basename(rfile).split(".", 2)
  dr = Call.new
  dr.number        = num
  dr.job_id        = job.id
  dr.project_id    = project.id
  dr.provider_id   = provider.id
  dr.answered      = true
  dr.busy          = false
  dr.audio_length  = File.size(rfile) / 16000.0
  dr.ring_length   = 0
  dr.caller_id     = num
  dr.save

  mr = dr.media
  ::File.open(rfile, "rb") do |fd|
    mr.audio = fd.read(fd.stat.size)
    mr.save
  end

  cnt += 1
  pct = (cnt / todo.length.to_f) * 100.0
  if cnt % 10 == 0
    job.update_progress(pct)
  end

  $stdout.puts "[ %#{"%.3d" % pct.to_i} ] Imported #{num} into project '#{project.name}' ##{project.id}"
end

job.update_progress(100)

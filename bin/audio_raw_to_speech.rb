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

require 'uri'
require 'net/http'
require 'json'

def usage
  $stderr.puts "Usage: #{$0} <input.raw> <output.json>"
  exit
end

#
# Script
#

inp = ARGV.shift
out = ARGV.shift

if (inp and inp == "-h") or not inp
  usage()
end

if out && File.exists?(out)
  $stderr.puts "Error: The output file already exists: #{out}"
  exit(0)
end

raw = WarVOX::Audio::Raw.from_file(inp)
res = nil
flac = raw.to_flac
akey = WarVOX::Config.gcloud_key

if ! akey
  $stderr.puts "Error: A gcloud API key needs to be configured"
  exit(1)
end

uri = URI('https://speech.googleapis.com/v1/speech:recognize?key=' + akey)
req = Net::HTTP::Post.new(uri, initheader = {'Content-Type' =>'application/json'})

loop do
  req.body =
  {
    "initialRequest" => {
      "encoding"     => "FLAC",
      "sampleRate"   => 16000,
    },
    "audioRequest" => {
      "content" => [flac].pack("m*").gsub(/\s+/, '')
    }
  }.to_json

begin
  http = Net::HTTP.new(uri.hostname, uri.port)
  http.use_ssl = true
  res = http.request(req)

  break if res.code.to_s == "200"
  $stderr.puts "Retrying due to #{res.code} #{res.message}..."
rescue ::Interrupt
  exit(0)
rescue ::Exception
  $stderr.puts "Exception: #{$!} #{$!.backtrace}"
end
  sleep(1)
end

if out
  ::File.open(out, "wb") do |fd|
    fd.write(res.body)
  end
else
  $stdout.write(res.body)
end

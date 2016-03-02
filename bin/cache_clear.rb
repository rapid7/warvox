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


$stderr.puts "[*] Loading database environment..."

require 'config/boot'
require 'config/environment'


$stderr.puts "[*] Clearing the report cache..."
Saulabs::Reportable::ReportCache.delete_all

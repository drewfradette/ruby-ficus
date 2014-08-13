#!/usr/bin/env ruby
require 'ficus'
require 'pp'

ficus = Ficus.load_file('sample.conf').validation do
  section /^server\d?$/ do
    required 'active'
    optional 'state', 'pending'
  end

  section /^server[A-Z]?$/i do
    required 'active'
    optional 'state', 'running'
  end
end

if ficus.valid?
  pp ficus.config
else
  puts "Invalid Configuration:"
  ficus.errors.each {|err| puts err.to_s}
end

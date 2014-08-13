#!/usr/bin/env ruby
require 'ficus'
require 'pp'

ficus = Ficus.load_file('sample.conf').validation do
  # Note: The DSL is evaluated in order so be sure to
  #       declare your templates before you use them.
  template :server do
    required 'ip_address'
    optional 'state', 'pending'
  end

  section 'web',   template: :server
  section 'db',    template: :server
  section 'cache', template: :server
end

if ficus.valid?
  pp ficus.config
else
  ficus.errors.each {|err| puts err.to_s}
end

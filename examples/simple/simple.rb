#!/usr/bin/env ruby
require 'ficus'
require 'pp'

ficus = Ficus.load_file('sample.conf').validation do

  required 'key1'
  required 'key2'

  section 'section1' do
    required 'active'
    optional 'url', 'http://drewfradette.ca'
  end

  section 'section2', optional: true do
    required 'key3'
  end
end

if ficus.valid?
  pp ficus.config
else
  ficus.errors.each {|err| puts err.to_s}
end

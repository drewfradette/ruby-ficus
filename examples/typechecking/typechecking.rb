#!/usr/bin/env ruby
require 'ficus'
require 'pp'

ficus = Ficus.load_file('sample.conf').validation do
  required 'active', :boolean
  required 'size',   :number
  required 'name',   :string

  optional 'grep', 'lorem ipsum', /est qui dolorem/
end

if ficus.valid?
  pp ficus.config
else
  ficus.errors.each {|err| puts err.to_s}
end

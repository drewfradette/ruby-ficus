$:.unshift File.join(File.dirname(__FILE__), '..')

require 'rspec'

if RUBY_VERSION.to_f >= 1.9
  puts 'Enabling coverage'
  require 'simplecov'
  SimpleCov.add_filter 'vendor'
  SimpleCov.add_filter 'spec'
  SimpleCov.start
end

RSpec.configure do |config|
  require 'lib/ficus'
end



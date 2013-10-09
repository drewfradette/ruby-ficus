require 'yaml'
require 'recursive-open-struct'

class Ficus < RecursiveOpenStruct
  class ConfigError < StandardError; end
  class << self
    attr_accessor :log, :verbose

    def load(file, &block)
      @log = []
      yaml = YAML.load File.read(file)
      config = Ficus.new(yaml, :recurse_over_arrays => true)
      config.instance_eval(&block) if block_given?

      errors = log.select{|v| v =~ /^\[ERR\]/}
      if errors.size > 0
        log.each{|v| puts v} if ENV['DEBUG']
        raise ConfigError.new("Unable to start due to invalid settings")
      end
      config
    end

    def log(log = {})
      @log << log
    end
  end

  def section(name, args = {}, &block)
    section = self.send(name)
    if section.nil?
      level = args[:optional] ? 'WARN' : 'ERR'
      Ficus.log "[#{level}] Section #{name} is not defined"
    else
      section.parent = self.parent ? "#{self.parent}.#{name}" : name
      section.instance_eval &block if block_given?
    end
  end

  def optional(name, default)
    self.send("#{name}=", default) if self.send(name).nil?
  end

  def required(name)
    prefix = self.parent ? "#{self.parent}." : nil
    Ficus.log "[ERR] Option #{prefix}#{name} is not defined" if self.send(name).nil?
  end
end

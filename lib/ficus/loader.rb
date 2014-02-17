class Ficus
  class << self
    attr_accessor :verbose, :logger, :errors, :warnings

    # Load the configuration file and validate.
    def load(file, &block)
      @errors, @warnings, @config = [], [], nil
      ficus = Ficus.new config file
      ficus.instance_eval &block if block_given?

      warnings.each { |e| logger.warn e }
      errors.each { |e| logger.error e }
      raise ConfigError.new('Unable to start due to invalid settings') if errors.size > 0

      ficus.struct
    end

    def error(msg)
      @errors << msg
    end

    def warning(msg)
      @warnings << msg
    end

    protected
    def config(file)
      RecursiveOpenStruct.new(YAML.load File.read(file), :recurse_over_arrays=>false)
    end

    def logger
      @logger ||= Logger.new(STDERR).tap { |l| l.level = Logger::WARN }
    end
  end
end


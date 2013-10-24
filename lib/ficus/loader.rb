class Ficus < RecursiveOpenStruct
  class << self
    attr_accessor :verbose, :logger, :errors, :warnings

    # Load the configuration file and validate.
    def load(file, &block)
      @errors, @warnings, @config = [], [], nil
      config(file).instance_eval(&block) if block_given?

      warnings.each { |e| logger.warn e }
      errors.each { |e| logger.error e }
      raise ConfigError.new('Unable to start due to invalid settings') if errors.size > 0
      config(file)
    end

    def error(msg)
      @errors << msg
    end

    def warning(msg)
      @warnings << msg
    end

    protected
    def config(file)
      if @config.nil?
        yaml = YAML.load File.read(file)
        @config = Ficus.new(yaml, :recurse_over_arrays => true)
      end
      @config
    end

    def logger
      @logger ||= Logger.new(STDERR).tap { |l| l.level = Logger::WARN }
    end
  end
end


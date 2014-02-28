class Ficus
  class << self

    # Load the configuration file and validate.
    def load(file, &block)
      ficus = Ficus.new config file
      ficus.instance_eval &block if block_given?
      raise ConfigError.new(ficus.errors) unless ficus.errors.empty?
      ficus.struct
    end

    protected

    def config(file)
      RecursiveOpenStruct.new(YAML.load(File.read(file)), :recurse_over_arrays=>false)
    end

    def read

    end

  end
end


class Ficus

  class NoSection < StandardError; end

  class ConfigError < StandardError
    attr_reader :errors

    def initialize( errors )
      @errors = errors
    end

    def to_s
      "Validation failed:\n #{errors.join("\t\n")}"
    end
  end


end

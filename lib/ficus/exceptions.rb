class Ficus

  # For errors with the input ficus script.
  class ValidateError < StandardError; end

  # Internal error used for reporting errors when a required section is missing.
  # This should be removed: Exceptions should not be expected in normal operation.
  class NoSection < StandardError; end

  # Public error, used to report errors with the input to be validated by the ficus script.
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

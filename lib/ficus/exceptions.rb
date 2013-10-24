class Ficus < RecursiveOpenStruct
  class ConfigError < StandardError; end
  class NoSection < StandardError; end
end

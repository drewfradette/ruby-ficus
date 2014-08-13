require 'yaml'

class Ficus
  class MissingValidation < StandardError; end

  class << self
    def load_file(filename)
      Ficus.load(YAML.load_file(filename))
    end

    def load(data)
      Ficus.new data
    end
  end

  attr_accessor :config, :errors, :opts, :schema, :templates

  TYPES = {
    string:  [String],
    number:  [Fixnum, Float],
    boolean: [TrueClass, FalseClass],
    array:   [Array],
    section: [Hash],
  }

  def initialize(config, opts = {})
    self.config = config
    self.opts = opts
    self.templates = {}
    self.errors = []
  end

  def validation(&block)
    self.schema = block
    return self
  end

  def valid?
    raise MissingValidation.new('no validation block specified') if self.schema.nil?
    self.errors = []
    instance_eval(&self.schema)
    return self.errors.empty?
  end

  def config
    @config ||= {}
  end

  def template(name, &block)
    self.templates[name] = block
  end

  def section(name, section_opts = {}, &block)
    if sections(name).nil?
      return if section_opts.fetch(:optional, false)
      msg = (name.class == Regexp) ? "no matches in #{heritage}" : "undefined"
      error heritage(name), msg
      return
    end

    sections(name).each do |key|
      # Ensure that the section is valid
      if !self.valid_type?(self.get(key), :section)
        error heritage(key), "must be section"
        next
      end

      # Set the validation block
      validation_block = block if block_given?
      template_name = section_opts.fetch(:template, false)
      if template_name
        if !self.templates.key?(template_name)
          error heritage(key), "undefined template #{template_name}"
          next
        end
        validation_block = self.templates[template_name]
      end

      # Get to work
      leaf = Ficus.new self.get(key), heritage: heritage(key)
      leaf.validation(&validation_block) unless validation_block.nil?
      if leaf.valid?
        # Update the data for the leaf section as 'optional' can modify the data.
        self.config[key] = leaf.config
      else
        # Update the errors raise by the leaf
        self.errors += leaf.errors
      end
    end
  end

  def optional(name, default, type = nil)
    value = exists?(name) ? get(name) : default
    if !valid_type?(value, type)
      error heritage(name), "must be #{type}"
    else
      self.config[name] = value
    end
  end

  def required(name, type = nil)
    if self.config.key?(name)
      error heritage(name), "must be #{type}" unless self.valid_type? get(name), type
    else
      error heritage(name), "undefined"
    end
  end

  protected

  def error(name, message)
    self.errors << Error.new(name, message)
  end

  def exists?(key)
    self.config.key?(key)
  end

  def get(key)
    self.config.fetch(key)
  end

  def heritage(postfix = nil)
    if postfix.nil?
      self.opts.fetch(:heritage, [])
    else
      self.opts.fetch(:heritage, []) + [postfix.to_s]
    end
  end

  def sections(name)
    # Collect the sections
    if name == :all
      self.config.keys
    elsif name.class == Regexp
      self.config.select{|k,v| k =~ name}.keys
    elsif self.config.key?(name)
      {name => self.config[name]}.keys
    else
      nil
    end
  end

  # Ensure value is a valid type.
  def valid_type?(value, type)
    if type.nil?
      return true
    elsif type.class == Regexp
      !!(type =~ value.to_s)
    else
      TYPES[type].include?(value.class)
    end
  end

  class Error
    attr_accessor :name, :message
    def initialize(name, message)
      self.name = name
      self.message = message
    end

    def to_s
      "#{name.join('.')}: #{message}"
    end
  end
end

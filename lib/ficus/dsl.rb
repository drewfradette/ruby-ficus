class Ficus

  attr_reader :struct, :errors, :templates

  def initialize(struct, errors=[])
    @struct, @errors = struct, errors

    # Fail if attempt is made to reference an invalid template
    @templates = Hash.new{ |hash, key|
      fail Ficus::ValidateError.new "Invalid template: #{key}"
    }
  end

  def parent
    struct.parent
  end

  def parent=(parent)
    struct.parent = parent
  end

  def template(name, &block)
    templates[name] = block
  end

  def section(name, args = {}, &block)
    sections(name).each do |s|
      s.parent = parent ? "#{parent}.#{name}" : name
      s.instance_eval(&block) if block_given?
      s.instance_eval(&templates[args[:template]]) if args[:template]
    end
  rescue NoSection
    unless args[:optional]
      errors << "Section #{name} is not defined"
    end
  end

  def sections(name)
    if name == :all
      sections(/.*/)
    elsif name.is_a? Regexp
      matches = self.struct.marshal_dump.keys
      matches.map do |k|
        unless k == :parent
          recurse k
        end
      end.compact!
    else
      [recurse(name)].tap do |array|
        raise NoSection.new if array.first.nil?
      end
    end
  end

  def optional(name, default)
    struct.send("#{name}=", default) if struct.send(name).nil?
  end

  def required(name)
    prefix = "#{parent}." if parent
    errors << "Option #{prefix}#{name} is not defined" if struct.send(name).nil?
  end

  def recurse(symbol, default=nil)
    s = struct.send symbol || struct.send("#{symbol}=", default) || default
    Ficus.new(s, errors) if !!s
  end

end

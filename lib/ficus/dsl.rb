class Ficus

  attr_reader :struct

  def initialize(struct)
    @struct = struct
  end

  def parent
    struct.parent
  end

  def parent=(parent)
    struct.parent = parent
  end

  def section(name, args = {}, &block)
    sections(name).each do |s|
      s.parent = parent ? "#{parent}.#{name}" : name
      s.instance_eval(&block) if block_given?
    end
  rescue NoSection
    if args[:optional] == true
      Ficus.warning("Section #{name} is not defined")
    else
      Ficus.error("Section #{name} is not defined")
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
    Ficus.error "Option #{prefix}#{name} is not defined" if struct.send(name).nil?
  end

  def recurse(symbol, default=nil)
    s = struct.send symbol
    if s.nil?
      struct.send("#{symbol}=", default) if s.nil?
      s = default
    end
    Ficus.new s if !!s
  end

end

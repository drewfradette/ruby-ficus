class Ficus < RecursiveOpenStruct
  def section(name, args = {}, &block)
    sections(name).each do |s|
      s.parent = self.parent ? "#{self.parent}.#{name}" : name
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
      matches = self.marshal_dump.keys
      matches.map { |k| self.send(k) unless k == :parent }.compact!
    else
      s = self.send(name)
      raise NoSection.new if s.nil?
      [s]
    end
  end

  def optional(name, default)
    self.send("#{name}=", default) if self.send(name).nil?
  end

  def required(name)
    prefix = self.parent ? "#{self.parent}." : nil
    Ficus.error "Option #{prefix}#{name} is not defined" if self.send(name).nil?
  end
end

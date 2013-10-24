# Ficus

A simple YAML configuration DSL that does runtime validation.

## Installation

Add this line to your application's Gemfile:

    gem 'ficus'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ficus

## Usage

Here is an example YAML config file:

```yaml
# config.yml
---
section_1:
  key1: value1
  key2: value2

section_2:
  key4: value4

optional_section:
  key5: value5

pattern_section_1:
  key6: value6

pattern_section_2:
  key6: value6

```

And now we can use Ficus to load the config and validate it at the same time.

```ruby
require 'ficus'

config = Ficus.load 'config.yml' do
  section 'section_1' do
    required 'key1'
    required 'key2'

    optional 'key3', 'value3'
  end

  section 'section_2'  do
    required 'key4'
  end

  section 'optional_section', :optional => true do
    required 'key5'
  end

  section 'not_defined', :optional => true do
    require 'key6'
  end

  section /^pattern_section_.+/ do
    require 'key6'
  end
end

config.section_1.key1         # value1
config.section_1.key2         # value2
config.section_1.key3         # value3
config.section_2.key4         # value4
config.not_defined            # nil
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

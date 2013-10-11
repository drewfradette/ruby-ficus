# Ficus

A simple YAML configuration DSL that does runtime validation.

## Important Note
This uses the [`recursive-open-struct`](https://github.com/aetherknight/recursive-open-struct) but due to gem missing a [crucial fix](https://github.com/aetherknight/recursive-open-struct/commit/0c16caa1b9a19d12e97829f02083f0b7d21f0100) 
I have simply added the latest version with the fix to the `lib`. When it's fixed in rubygems, I will add it as a gem dependency.

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

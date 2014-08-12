require 'spec_helper'
require 'tempfile'

require 'ficus'

describe Ficus do
  def config
    {
      'general' => {'key1' => 'value1', 'key2' => 'value2', 'key3' =>'value3'},
      'misc' => {'key4' => 'value4', 'list' => {
        'item1' => 'value1',
        'item2' => 'value2'
      }}
    }
  end

  it 'will load the config from a string' do
    ficus = Ficus.load(config)
    expect(ficus.config).to eq config
  end

  it 'will load the config from a file' do
    Tempfile.open('config.yml') do |file|
      file.write config.to_yaml
      file.close

      ficus = Ficus.load_file file.path
      expect(ficus.config).to eq config
    end
  end

  it 'will validate the config with an optional missing section' do
    Ficus.load(config).tap do |ficus|
      ficus.validation do
        section 'not_real', optional: true
      end
      expect(ficus.valid?).to eq true
    end
  end

  it 'will fail to validate the config due to a missing section' do
    Ficus.load(config).tap do |ficus|
      ficus.validation do
        section 'not_real'
      end

      expect(ficus.valid?).to eq false
      expect(ficus.errors.size).to eq 1
      expect(ficus.errors.first.to_s).to match(/not_real/)
    end
  end

  it 'will fail to validate the config due to a required parameter' do
    Ficus.load(config).tap do |ficus|
      ficus.validation do
        section 'general', optional: true do
          required 'fake_param'
        end
      end

      expect(ficus.valid?).to eq false
      expect(ficus.errors.size).to eq 1
      expect(ficus.errors.first.to_s).to match(/general.fake_param/)
    end
  end

  it 'will validate the config and fill in the optional value' do
    Ficus.load(config).tap do |ficus|
      ficus.validation do
        section 'general' do
          optional 'newparam', 'value2'
        end
      end

      expect(ficus.valid?).to eq true
      expect(ficus.config['general']['newparam']).to eq 'value2'
    end
  end

  it 'will validate conformant subsections' do
    hash = {'subsections' => {'section1' => {'key1' => 'value1'}, 'section2' => {'key1' => 'value1'}}}

    Ficus.load(hash).tap do |ficus|
      ficus.validation do
        section 'subsections' do
          section /^section/ do
            required 'key1'
          end
        end
      end

      expect(ficus.valid?).to eq true
      expect(ficus.config['subsections']['section1']['key1']).to eq 'value1'
      expect(ficus.config['subsections']['section2']['key1']).to eq 'value1'
    end
  end

  it 'will fail to validate nonconformant subsections' do
    hash = {'subsections' => {'section1' => {'key1' => 'value1'}, 'section2' => {}}}

    Ficus.load(hash).tap do |ficus|
      ficus.validation do
        section 'subsections' do
          section /^section/ do
            required 'key1'
          end
        end
      end

      expect(ficus.valid?).to eq false
      expect(ficus.errors.size).to eq 1
      expect(ficus.errors.first.to_s).to match(/subsections.section2.key1/)
    end
  end

  it 'will fail validate all subsections' do
    hash = {'subsections' => {'section1' => {'key1' => 'value1'},'section2' => {}}}

    Ficus.load(hash).tap do |ficus|
      ficus.validation do
        section 'subsections' do
          section :all do
            required 'key1'
          end
        end
      end

      expect(ficus.valid?).to eq false
      expect(ficus.errors.size).to eq 1
      expect(ficus.errors.first.to_s).to match(/subsections.section2.key1/)
    end
  end

  it 'will validate based on a template' do
    hash = {'section1' => {'key1' => 'value1'}}

    Ficus.load(hash).tap do |ficus|
      ficus.validation do
        template 'template1' do
          required 'key1'
        end
        section 'section1', template: 'template1'
      end
      expect(ficus.valid?).to eq true
      expect(ficus.config['section1']['key1']).to eq 'value1'
    end
  end

  it 'will fail to validate due to failing to conform to a template' do
    hash = {'section1' => {}}

    Ficus.load(hash).tap do |ficus|
      ficus.validation do
        template 'template1' do
          required 'key1'
        end
        section 'section1', :template=>'template1'
      end
      expect(ficus.valid?).to eq false
      expect(ficus.errors.size).to eq 1
      expect(ficus.errors.first.to_s).to match(/section1.key1/)
    end
  end

  it 'will fail to validate a reference to an invalid template' do
    hash = {'section1' => {}}

    Ficus.load(hash).tap do |ficus|
      ficus.validation do
        section 'section1', template: 'template1'
      end

      expect(ficus.valid?).to eq false
      expect(ficus.errors.first.to_s).to match(/undefined template template1/)
    end
  end

  it 'will fail to validate due to a parameter definde as a section' do
    hash = {'section1' => 'notarealsection'}

    Ficus.load(hash).tap do |ficus|
      ficus.validation do
        section 'section1'
      end

      expect(ficus.valid?).to eq false
      expect(ficus.errors.size).to eq 1
      expect(ficus.errors.first.to_s).to match(/must be/i)
    end
  end

  it 'will validate with type checking on optional parameters' do
    hash = {'number' => 3}

    Ficus.load(hash).tap do |ficus|
      ficus.validation do
        optional 'number', 1,     :number
        optional 'bool',   true,  :boolean
        optional 'name',  'drew', :string
        optional 'matcher', 'server5', /server\d/
      end

      expect(ficus.valid?).to eq true
    end
  end

  it 'will fail to validate with type checking on optional parameters' do
    hash = {}

    Ficus.load(hash).tap do |ficus|
      ficus.validation do
        optional 'number',  false,      :number
        optional 'bool',    'drew',     :boolean
        optional 'name',    123,        :string
        optional 'matcher', 'server5',  /zzzserver\d/
      end

      expect(ficus.valid?).to eq false
      expect(ficus.errors.size).to eq 4
    end
  end
  it 'will validate with type checking on required parameters' do
    hash = {'number' => 1, 'bool' => false,'name' => "drew"}

    Ficus.load(hash).tap do |ficus|
      ficus.validation do
        required 'number', :number
        required 'bool',   :boolean
        required 'name',   :string
      end

      expect(ficus.valid?).to eq true
    end
  end

  it 'will fail to validate due to type checking on required parameters' do
    hash = {'number' => false, 'bool' => "nope",'name' => 1}

    Ficus.load(hash).tap do |ficus|
      ficus.validation do
        required 'number', :number
        required 'bool',   :boolean
        required 'name',   :string
      end

      expect(ficus.valid?).to eq false
      expect(ficus.errors.size).to eq 3
      ficus.errors.each do |error|
        expect(error.to_s).to match(/must be/)
      end
    end
  end
end

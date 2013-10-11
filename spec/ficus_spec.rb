require 'spec_helper'

require 'tempfile'
require 'yaml'

require 'ficus'

describe Ficus do
  before :each do
    @config = {
      :general => {:key1=>'value1',:key2=>'value2',:key3=>'value3'},
      :misc    => {
        :key4 => 'value4',
        :list => {:item1 => 'value1', :item2 => 'value2'}
      }
    }
  end

  it 'should load the config without any validation' do
    config_file do |config|
      config = Ficus.load(config)

      config.to_h.should eq @config
    end
  end

  it 'should load the config with a warning about a missing section' do
    config_file do |config|
      config = Ficus.load(config) do
        section 'not_real', :optional => true
      end
      Ficus.log.count{|v| v =~ /^\[WARN\]/}.should eq 1
    end
  end

  it 'should load the config with a error about a missing section' do
    config_file do |config|
      expect {
        config = Ficus.load(config) do
          section 'not_real'
        end
      }.to raise_error Ficus::ConfigError

      Ficus.log.count{|v| v =~ /^\[ERR\]/}.should eq 1
    end
  end

  it 'should load the config but fail to validate' do
    config_file do |config|
      expect {
        config = Ficus.load(config) do
          section 'general', :optional => true do
            required 'fake_param'
          end
        end
      }.to raise_error Ficus::ConfigError
      Ficus.log.count{|v| v =~ /^\[ERR\]/}.should eq 1
    end
  end

  it 'should load the config but fill in the optional value' do
    config_file do |config|
      config = Ficus.load(config) do
        section 'general' do
          optional 'newparam', 'value2'
        end
      end
      @config.fetch(:general).fetch('newparam', nil).should eq nil
      config.general.newparam.should eq 'value2'
    end
  end

  it 'should validate conformant subsections' do
    hash = {
        :subsections => {
            :section1 => {:key1=>'value1'},
            :section2 => {:key1=>'value1'},
        }
    }

    config_file(hash) do |config|
      config = Ficus.load(config) do
        section 'subsections' do
          section /^section/ do
            required :key1
          end
        end
      end
      config.subsections.section1.key1.should eq 'value1'
      config.subsections.section2.key1.should eq 'value1'
    end
  end

  it 'should invalidate nonconformant subsections' do
    hash = {
        :subsections => {
            :section1 => {:key1=>'value1'},
            :section2 => {},
        }
    }

    config_file(hash) do |config|
      expect {
        Ficus.load(config) do
          section 'subsections' do
            section /^section/ do
              required :key1
            end
          end
        end
      }.to raise_error Ficus::ConfigError
    end
  end

  it 'should validate all subsections' do
    hash = {
        :subsections => {
            :section1 => {:key1=>'value1'},
            :section2 => {},
        }
    }

    config_file(hash) do |config|
      expect {
        Ficus.load(config) do
          section 'subsections' do
            section :all do
              required :key1
            end
          end
        end
      }.to raise_error Ficus::ConfigError
    end
  end

  def config_file(hash=@config)
    Tempfile.open('config.yml') do |config|
      config.write hash.to_yaml
      config.close

      yield config.path
    end
  end
end

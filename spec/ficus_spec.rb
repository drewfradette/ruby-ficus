require 'spec_helper'
require 'tempfile'
require 'yaml'
require 'ficus'

describe Ficus do
  before :each do
    @config = {
      :general => {:key1=>'value1', :key2=>'value2', :key3=>'value3'},
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

  it 'should load the config with an optional missing section' do
    config_file do |config|
      config = Ficus.load(config) do
        section 'not_real', :optional => true
      end
    end
  end

  it 'should load the config with a error about a missing section' do
    config_file do |config|
      expect_errors(1) do
        config = Ficus.load(config) do
          section 'not_real'
        end
      end
    end
  end

  it 'should load the config but fail to validate' do
    config_file do |config|
      expect_errors(1) do
        config = Ficus.load(config) do
          section 'general', :optional => true do
            required 'fake_param'
          end
        end
      end
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
      expect do
        Ficus.load(config) do
          section 'subsections' do
            section /^section/ do
              required :key1
            end
          end
        end
      end.to raise_error Ficus::ConfigError
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
      expect do
        Ficus.load(config) do
          section 'subsections' do
            section :all do
              required :key1
            end
          end
        end
      end.to raise_error Ficus::ConfigError
    end
  end

  it 'should validate a template' do
    hash = {
        :section1=> {:key1=>'value1'}
    }

    config_file(hash) do |config|
      config = Ficus.load(config) do
        template 'template1' do
          required :key1
        end
        section 'section1', :template=>'template1'
      end
      config.section1.key1.should eq 'value1'
    end
  end

  it 'should report a configuration error for a failure to conform to a template' do
    hash = {
        :section1=> {}
    }

    config_file(hash) do |config|
      expect {
        Ficus.load(config) do
          template 'template1' do
            required :key1
          end
          section 'section1', :template=>'template1'
        end
      }.to raise_error Ficus::ConfigError
    end
  end

  it 'should fail to validate a reference to an invalid template' do
    config_file({
        :section1=>{}
                }) do |config|
      expect {
        Ficus.load(config) do
          section 'section1', :template=>'template1'
        end
      }.to raise_error Ficus::ValidateError
    end
  end

  def expect_errors(num_errors, &block)
    yield
  rescue Ficus::ConfigError => bang
    bang.errors.size.should eq num_errors
  end

  def config_file(hash=@config)
    Tempfile.open('config.yml') do |config|
      config.write hash.to_yaml
      config.close
      yield config.path
    end
  end

  def logger
    Logger.new(STDOUT).tap { |log| log.level = Logger::FATAL }
  end
end

require 'rails_helper'

describe FeatureSet do

  before(:each) do
    # override whatever is in the settings file with these settings
    Settings.enabled_features.sars = Config::Options.new({
                                                              :"Rails-development" => true,
                                                              :"Host-dev" => true,
                                                              :"Host-demo" => true,
                                                              :"Host-staging" => false,
                                                              :"Host-production" => false
                                                         })
  end

  before(:each) { @saved_env = ENV['ENV'] }

  after(:each)  { ENV['ENV'] = @saved_env }


  describe '#enabled?' do
    context 'test environment on local host' do
      it 'is enabled' do
        expect(FeatureSet.sars.enabled?).to be true
      end
    end

    context 'development environment on local host' do
      it 'is enabled' do
        expect(Rails.env).to receive(:development?).and_return(true)
        expect(FeatureSet.sars.enabled?).to be true
      end
    end

    context 'production environment on dev server' do
      it 'is enabled' do
        ENV['ENV'] = 'dev'
        expect(FeatureSet.sars.enabled?).to be true
      end
    end

    context 'production environment on demo server' do
      it 'is enabled' do
        ENV['ENV'] = 'demo'
        expect(FeatureSet.sars.enabled?).to be true
      end
    end

    context 'production environment on staging server' do
      it 'is enabled' do
        ENV['ENV'] = 'staging'
        expect(FeatureSet.sars.enabled?).to be false
      end
    end

    context 'production environment on prod server' do
      it 'is enabled' do
        ENV['ENV'] = 'prod'
        expect(FeatureSet.sars.enabled?).to be false
      end
    end
  end


  describe '#enable!' do
    context 'on an environment where it is disabled' do
      it 'is enabled' do
        ENV['ENV'] = 'prod'
        expect(FeatureSet.sars.enabled?).to be false
        FeatureSet.sars.enable!
        expect(FeatureSet.sars.enabled?).to be true
      end
    end
  end

  describe '#disable!' do
    context 'on an environment where it is enabled' do
      it 'is disabled' do
        ENV['ENV'] = 'demo'
        expect(FeatureSet.sars.enabled?).to be true
        FeatureSet.sars.disable!
        expect(FeatureSet.sars.enabled?).to be false
      end
    end
  end


end

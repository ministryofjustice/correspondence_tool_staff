require 'rails_helper'

describe HostEnv do
  RSpec.shared_examples "is safe?" do
    describe 'safe?' do
      it 'returns true' do
        expect(HostEnv.safe?).to be true
      end
    end

    describe 'safe' do
      before(:each) { @yielded = false }
      it 'yields to the block' do
        HostEnv.safe do
          @yielded = true
        end
        expect(@yielded).to be true
      end
    end
  end

  describe 'local machine environment' do
    context 'local development rails environment' do
      before(:each) do
        ENV['RAILS_ENV'] = 'development'
      end

      after(:each) do
        ENV['RAILS_ENV'] = 'test'
      end

      describe 'HostEnv.staging?' do
        it 'returns false' do
          expect(HostEnv.staging?).to be false
        end
      end

      describe 'HostEnv.development?' do
        it 'returns false' do
          expect(HostEnv.development?).to be false
        end
      end

      describe 'HostEnv.qa?' do
        it 'returns false' do
          expect(HostEnv.qa?).to be false
        end
      end

      include_examples "is safe?"
    end

    context 'local test rails environment' do
      describe 'HostEnv.staging?' do
        it 'returns false' do
          expect(HostEnv.staging?).to be false
        end
      end

      describe 'HostEnv.development?' do
        it 'returns true' do
          expect(HostEnv.development?).to be false
        end
      end

      describe '.test?' do
        it 'returns true' do
          expect(HostEnv.test?).to be true
        end
      end

      describe 'HostEnv.qa?' do
        it 'returns false' do
          expect(HostEnv.qa?).to be false
        end
      end

      include_examples "is safe?"
    end
  end


  # Cloud Platform Environments
  #
  # Namespace       RAILS_ENV       ENV
  # --------------------------------------------------
  # Demo            production      demo
  # Development     development     dev
  # Production      production      prod
  # QA              development     qa
  # Staging         production      staging

  describe '5 cloud platform infrastructure environments' do
    context '1. demo server' do
      before(:each) do
        ENV['RAILS_ENV'] = 'production'
        ENV['ENV'] = 'demo'
      end

      after(:each) do
        ENV['RAILS_ENV'] = 'test'
        ENV['ENV'] = nil
      end

      it 'is a demo server environment' do
        expect(HostEnv.demo?).to be true
      end

      it 'is not another environment' do
        expect(HostEnv.development?).to be false
        expect(HostEnv.production?).to be false
        expect(HostEnv.qa?).to be false
        expect(HostEnv.staging?).to be false
      end

      include_examples "is safe?"
    end

    context '2. development server' do
      before(:each) do
        ENV['RAILS_ENV'] = 'development'
        ENV['ENV'] = 'dev'
      end

      after(:each) do
        ENV['RAILS_ENV'] = 'test'
        ENV['ENV'] = nil
      end

      it 'is a development server environment' do
        expect(HostEnv.development?).to be true
      end

      it 'is not another environment' do
        expect(HostEnv.demo?).to be false
        expect(HostEnv.production?).to be false
        expect(HostEnv.qa?).to be false
        expect(HostEnv.staging?).to be false
      end

      include_examples "is safe?"
    end

    context '3. production server' do
      before(:each) do
        ENV['RAILS_ENV'] = 'production'
        ENV['ENV'] = 'prod'
        allow(Rails.env).to receive(:test?).and_return(false)
      end

      after(:each) do
        ENV['RAILS_ENV'] = 'test'
        ENV['ENV'] = nil
      end

      it 'is a production server environment' do
        expect(HostEnv.production?).to be true
      end

      it 'is not another environment' do
        expect(HostEnv.demo?).to be false
        expect(HostEnv.development?).to be false
        expect(HostEnv.qa?).to be false
        expect(HostEnv.staging?).to be false
      end

      describe 'safe?' do
        it 'returns false' do
          expect(HostEnv.safe?).to be false
        end
      end

      describe 'safe' do
        before(:each) { @yielded = false }
        it 'raises does not yields to the block' do
          expect {
            HostEnv.safe do
              @yielded = true
            end
          }.to raise_error RuntimeError, 'This task can not be run in a live production environment'
          expect(@yielded).to be false
        end
      end
    end

    context '4. qa server' do
      before(:each) do
        ENV['RAILS_ENV'] = 'development'
        ENV['ENV'] = 'qa'
      end

      after(:each) do
        ENV['RAILS_ENV'] = 'test'
        ENV['ENV'] = nil
      end

      it 'is a qa server environment' do
        expect(HostEnv.qa?).to be true
      end

      it 'is not another environment' do
        expect(HostEnv.demo?).to be false
        expect(HostEnv.development?).to be false
        expect(HostEnv.production?).to be false
        expect(HostEnv.staging?).to be false
      end

      include_examples "is safe?"
    end

    context '5. staging server' do
      before(:each) do
        ENV['RAILS_ENV'] = 'production'
        ENV['ENV'] = 'staging'
      end

      after(:each) do
        ENV['RAILS_ENV'] = 'test'
        ENV['ENV'] = nil
      end

      it 'is a staging server environment' do
        expect(HostEnv.staging?).to be true
      end

      it 'is not another environment' do
        expect(HostEnv.demo?).to be false
        expect(HostEnv.development?).to be false
        expect(HostEnv.production?).to be false
        expect(HostEnv.qa?).to be false
      end

      include_examples "is safe?"
    end
  end
end

require 'rails_helper'

describe HostEnv do

  context 'development rails environment' do
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

    describe 'HostEnv.dev?' do
      it 'returns false' do
        expect(HostEnv.dev?).to be false
      end
    end

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

  context 'test rails environment' do

    describe 'HostEnv.staging?' do
      it 'returns false' do
        expect(HostEnv.staging?).to be false
      end
    end

    describe 'HostEnv.dev?' do
      it 'returns true' do
        expect(HostEnv.dev?).to be false
      end
    end

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

  context 'production rails environment' do
    context 'dev server' do
      before(:each) do
        ENV['RAILS_ENV'] = 'production'
        ENV['ENV'] = 'dev'
      end

      after(:each) do
        ENV['RAILS_ENV'] = 'test'
        ENV['ENV'] = nil
      end

      describe 'HostEnv.staging?' do
        it 'returns false' do
          expect(HostEnv.staging?).to be false
        end
      end

      describe 'HostEnv.dev?' do
        it 'returns true' do
          expect(HostEnv.dev?).to be true
        end
      end

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

    context 'staging server' do
      before(:each) do
        ENV['RAILS_ENV'] = 'production'
        ENV['ENV'] = 'staging'
      end

      after(:each) do
        ENV['RAILS_ENV'] = 'test'
        ENV['ENV'] = nil
      end

      describe 'HostEnv.staging?' do
        it 'returns true' do
          expect(HostEnv.staging?).to be true
        end
      end

      describe 'HostEnv.dev?' do
        it 'returns false' do
          expect(HostEnv.dev?).to be false
        end
      end

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

    context 'production server' do
      before(:each) do
        ENV['RAILS_ENV'] = 'production'
        ENV['ENV'] = 'prod'
        allow(Rails.env).to receive(:test?).and_return(false)
      end

      after(:each) do
        ENV['RAILS_ENV'] = 'test'
        ENV['ENV'] = nil
      end

      describe 'HostEnv.staging?' do
        it 'returns false' do
          expect(HostEnv.staging?).to be false
        end
      end

      describe 'HostEnv.dev?' do
        it 'returns false' do
          expect(HostEnv.dev?).to be false
        end
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
  end



end

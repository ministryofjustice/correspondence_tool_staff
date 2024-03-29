require "rails_helper"

# rubocop:disable RSpec/InstanceVariable
describe HostEnv do
  RSpec.shared_examples "is safe?" do
    describe "safe?" do
      it "returns true" do
        expect(described_class.safe?).to be true
      end
    end

    describe "safe" do
      before { @yielded = false }

      it "yields to the block" do
        described_class.safe do
          @yielded = true
        end
        expect(@yielded).to be true
      end
    end
  end

  describe "local machine environment" do
    context "when local development rails environment" do
      before do
        ENV["RAILS_ENV"] = "development"
      end

      after do
        ENV["RAILS_ENV"] = "test"
      end

      describe "HostEnv.staging?" do
        it "returns false" do
          expect(described_class.staging?).to be false
        end
      end

      describe "HostEnv.development?" do
        it "returns false" do
          expect(described_class.development?).to be false
        end
      end

      describe "HostEnv.qa?" do
        it "returns false" do
          expect(described_class.qa?).to be false
        end
      end

      include_examples "is safe?"
    end

    context "when local test rails environment" do
      describe "HostEnv.staging?" do
        it "returns false" do
          expect(described_class.staging?).to be false
        end
      end

      describe "HostEnv.development?" do
        it "returns true" do
          expect(described_class.development?).to be false
        end
      end

      describe ".test?" do
        it "returns true" do
          expect(described_class.test?).to be true
        end
      end

      describe "HostEnv.qa?" do
        it "returns false" do
          expect(described_class.qa?).to be false
        end
      end

      include_examples "is safe?"
    end
  end

  # Cloud Platform Environments
  #
  # Namespace       RAILS_ENV       ENV
  # --------------------------------------------------
  # Development     production      dev
  # Production      production      prod
  # QA              production      qa
  # Staging         production      staging

  describe "4 cloud platform infrastructure environments" do
    before do
      k8s_settings = YAML.load_file("config/kubernetes/#{namespace}/configmap.yaml")
      @envvars = k8s_settings["data"]
    end

    describe "1. development server" do
      let(:namespace) { "development" }

      before do
        ENV["RAILS_ENV"] = "production"
        ENV["ENV"] = "dev"
      end

      after do
        ENV["RAILS_ENV"] = "test"
        ENV["ENV"] = nil
      end

      it "is a development server environment" do
        expect(described_class.development?).to be true
        expect_k8s_settings
      end

      it "is not another environment" do
        expect(described_class.production?).to be false
        expect(described_class.qa?).to be false
        expect(described_class.staging?).to be false
      end

      include_examples "is safe?"
    end

    describe "2. production server" do
      let(:namespace) { "production" }

      before do
        ENV["RAILS_ENV"] = "production"
        ENV["ENV"] = "prod"
        allow(Rails.env).to receive(:test?).and_return(false)
      end

      after do
        ENV["RAILS_ENV"] = "test"
        ENV["ENV"] = nil
      end

      it "is a production server environment" do
        expect(described_class.production?).to be true
        expect_k8s_settings
      end

      it "is not another environment" do
        expect(described_class.development?).to be false
        expect(described_class.qa?).to be false
        expect(described_class.staging?).to be false
      end

      describe "safe?" do
        it "returns false" do
          expect(described_class.safe?).to be false
        end
      end

      describe "safe" do
        before { @yielded = false }

        it "raises does not yields to the block" do
          expect {
            described_class.safe do
              @yielded = true
            end
          }.to raise_error RuntimeError, "This task can not be run in a live production environment"
          expect(@yielded).to be false
        end
      end
    end

    describe "3. qa server" do
      let(:namespace) { "qa" }

      before do
        ENV["RAILS_ENV"] = "production"
        ENV["ENV"] = "qa"
      end

      after do
        ENV["RAILS_ENV"] = "test"
        ENV["ENV"] = nil
      end

      it "is a qa server environment" do
        expect(described_class.qa?).to be true
        expect_k8s_settings
      end

      it "is not another environment" do
        expect(described_class.development?).to be false
        expect(described_class.production?).to be false
        expect(described_class.staging?).to be false
      end

      include_examples "is safe?"
    end

    describe "4. staging server" do
      let(:namespace) { "staging" }

      before do
        ENV["RAILS_ENV"] = "production"
        ENV["ENV"] = "staging"
      end

      after do
        ENV["RAILS_ENV"] = "test"
        ENV["ENV"] = nil
      end

      it "is a staging server environment" do
        expect(described_class.staging?).to be true
        expect_k8s_settings
      end

      it "is not another environment" do
        expect(described_class.development?).to be false
        expect(described_class.production?).to be false
        expect(described_class.qa?).to be false
      end

      include_examples "is safe?"
    end

    def expect_k8s_settings
      expect(@envvars["RAILS_ENV"]).to eq ENV["RAILS_ENV"]
      expect(@envvars["ENV"]).to eq ENV["ENV"]
    end
  end
end
# rubocop:enable RSpec/InstanceVariable

require "rails_helper"

# rubocop:disable RSpec/InstanceVariable
describe FeatureSet do
  before do
    # override whatever is in the settings file with these settings
    Settings.enabled_features.sars = Config::Options.new({
      "Local": true,
      "Host-dev": true,
      "Host-staging": false,
      "Host-production": false,
    })
    @saved_env = ENV["ENV"]
  end

  after { ENV["ENV"] = @saved_env }

  describe "#enabled?" do
    context "when test environment on local host" do
      it "is enabled" do
        expect(described_class.sars.enabled?).to be true
      end
    end

    context "when development environment on local host" do
      it "is enabled" do
        allow(Rails.env).to receive(:development?).and_return(true)
        expect(described_class.sars.enabled?).to be true
      end
    end

    context "when production environment on dev server" do
      it "is enabled" do
        ENV["ENV"] = "dev"
        expect(described_class.sars.enabled?).to be true
      end
    end

    context "when production environment on staging server" do
      it "is enabled" do
        ENV["ENV"] = "staging"
        expect(described_class.sars.enabled?).to be false
      end
    end

    context "when production environment on prod server" do
      it "is enabled" do
        ENV["ENV"] = "prod"
        expect(described_class.sars.enabled?).to be false
      end
    end
  end

  describe "#enable!" do
    context "when on an environment where it is disabled" do
      it "is enabled" do
        ENV["ENV"] = "prod"
        expect(described_class.sars.enabled?).to be false
        described_class.sars.enable!
        expect(described_class.sars.enabled?).to be true
      end
    end
  end

  describe "#disable!" do
    context "when on an environment where it is enabled" do
      it "is disabled" do
        ENV["ENV"] = "dev"
        expect(described_class.sars.enabled?).to be true
        described_class.sars.disable!
        expect(described_class.sars.enabled?).to be false
      end
    end
  end

  describe "#respond_to?" do
    context "when a feature defined in the config" do
      it "responds true" do
        expect(described_class.respond_to?(:sars)).to be true
      end
    end

    context "when a method defined on the superclass" do
      it "responds true" do
        expect(described_class.respond_to?(:object_id)).to be true
      end
    end

    context "when unknown method" do
      it "responds false" do
        expect(described_class.respond_to?(:xxxx)).to be false
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable

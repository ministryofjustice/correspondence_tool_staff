require "rails_helper"

RSpec.describe DbHousekeeping do
  describe ".clean" do
    it "raises if Rails.env is not test" do
      original_env = Rails.env
      begin
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
        expect { described_class.clean(seed: false) }.to raise_error(/Refusing to clean non-test environment/)
      ensure
        allow(Rails).to receive(:env).and_return(original_env)
      end
    end

    it "does not raise in test env" do
      # Avoid actually truncating the DB in this spec; we only care that it doesn't raise
      allow(ActiveRecord::Base.connection).to receive(:execute)
      expect { described_class.clean(seed: false) }.not_to raise_error
    end
  end
end

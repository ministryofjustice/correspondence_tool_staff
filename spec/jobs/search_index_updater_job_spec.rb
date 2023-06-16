require "rails_helper"

describe SearchIndexUpdaterJob, type: :job do
  include ActiveJob::TestHelper

  let!(:k1) { create :case }

  describe "#perform" do
    it "processes k1" do
      expect(Case::Base).to receive(:find).with(k1.id).and_return(k1)

      expect(k1).to receive(:update_index)
      described_class.new.perform(k1.id)
    end

    it "sets k1 to clean" do
      described_class.new.perform(k1.id)
      expect(k1.reload).to be_clean
    end
  end
end

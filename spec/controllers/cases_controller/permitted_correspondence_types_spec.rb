require "rails_helper"

describe CasesController, type: :controller do # rubocop:disable RSpec/FilePath
  let(:manager)       { find_or_create :disclosure_bmt_user }
  let(:responder)     { find_or_create :branston_user }
  let(:controller)    { described_class.new }
  let!(:sar)          { find_or_create :sar_correspondence_type }
  let!(:sar_ir)       { find_or_create :sar_internal_review_correspondence_type }
  let!(:ico)          { find_or_create :ico_correspondence_type }

  before do
    find_or_create :offender_sar_complaint_correspondence_type
  end

  context "with manager" do
    before do
      allow(controller).to receive(:current_user).and_return(manager)
    end

    it "does permit SAR cases" do
      types = controller.__send__(:permitted_correspondence_types)
      expect(types).to include sar
    end

    it "does permit SAR INTERNAL REVIEW cases" do
      types = controller.__send__(:permitted_correspondence_types)
      expect(types).to include sar_ir
    end

    it "does permit ICO cases" do
      types = controller.__send__(:permitted_correspondence_types)
      expect(types).to include ico
    end
  end

  context "with responder (branston)" do
    before do
      allow(controller).to receive(:current_user).and_return(responder)
    end

    it "does not permit SAR cases " do
      types = controller.__send__(:permitted_correspondence_types)
      expect(types).not_to include sar
    end

    it "does not permit ICO cases" do
      types = controller.__send__(:permitted_correspondence_types)
      expect(types).not_to include ico
    end
  end
end

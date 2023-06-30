require "rails_helper"

describe Case::SAR::StandardDecorator do
  let(:decorated_sar_case) { create(:sar_case, subject_type: "member_of_the_public").decorate }

  it "instantiates the correct decorator" do
    expect(Case::SAR::Standard.new.decorate).to be_instance_of described_class
  end

  it "formats the requester type" do
    expect(decorated_sar_case.subject_type_display).to eq "Member of the public"
  end

  describe "#request_methods_sorted" do
    it "returns an ordered request methods list of options" do
      expect(decorated_sar_case.request_methods_sorted).to eq %w[email post unknown verbal web_portal]
    end
  end

  describe "#request_methods_for_display" do
    it 'does not return the "unknown" request method' do
      expect(decorated_sar_case.request_methods_for_display).to match_array %w[email post verbal web_portal]
    end

    it "returns an ordered request methods list of options for display" do
      expect(decorated_sar_case.request_methods_for_display).to eq %w[email post verbal web_portal]
    end
  end
end

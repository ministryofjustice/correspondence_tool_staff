require "rails_helper"

describe Case::ICO::SARDecorator do
  let(:ico_sar_case) { build_stubbed :ico_sar_case }

  it "instantiates the correct decorator" do
    expect(Case::ICO::SAR.new.decorate).to be_instance_of described_class
  end

  describe "#type_printer" do
    it "pretty prints Case" do
      expect(ico_sar_case.decorate.pretty_type).to eq "ICO appeal (SAR)"
    end
  end
end

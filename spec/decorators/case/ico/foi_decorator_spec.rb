require "rails_helper"

describe Case::ICO::FOIDecorator do
  let(:ico_foi_case) { build_stubbed :ico_foi_case }

  it "instantiates the correct decorator" do
    expect(Case::ICO::FOI.new.decorate).to be_instance_of described_class
  end

  describe "#type_printer" do
    it "pretty prints Case" do
      expect(ico_foi_case.decorate.pretty_type).to eq "ICO appeal (FOI)"
    end
  end
end

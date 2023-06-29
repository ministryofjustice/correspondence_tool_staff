require "rails_helper"

describe Case::OverturnedICO::FOIDecorator do
  let(:overturned_foi)    { create(:overturned_ico_foi) }
  let(:decorated_case)    { overturned_foi.decorate }

  describe "#type_printer" do
    it "pretty prints Case" do
      expect(decorated_case.pretty_type).to eq "ICO overturned (FOI)"
    end
  end

  describe "#original_case_description" do
    it "returns pretty description" do
      expect(decorated_case.original_case_description).to eq(
        "ICO appeal (FOI) #{overturned_foi.original_ico_appeal.number}",
      )
    end
  end
end

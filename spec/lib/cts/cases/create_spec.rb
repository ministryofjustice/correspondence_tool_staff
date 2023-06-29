require "rails_helper"
require "thor"

require "cts"
require "cts/cases/create"

describe CTS::Cases::Create, tag: :cli do
  let(:case_params) { { type: "Case::ICO::FOI", creator: create(:user, :orphan) } }
  let(:cts_creator) { described_class.new(Rails.logger, case_params) }

  describe "#new_ico_case" do
    context "when new default FOI ICO appeal" do
      it "returns a valid new ICO case" do
        foi = create(:rejected_case)
        kase = cts_creator.new_case

        # TODO: Please remove this once CTS::Cases::Create
        # is changed to create the original case (which bit?)
        kase.original_case_id = foi.id
        expect(kase).to be_valid
      end
    end
  end
end

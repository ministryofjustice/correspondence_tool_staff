require "rails_helper"

RSpec.describe ViewsHelper, type: :helper do
  describe "#Create a rejected offender sar" do
    context "with valid params" do
      subject(:data_request) do
        described_class.new(
          offender_sar_case: build(:offender_sar_case),
          user: build_stubbed(:user),
          location: "X" * 500, # Max length
          request_type: "all_prison_records",
          request_type_note: "",

          )

        data_request_title = get_headings(offender_sar_case, "cases.new.offender_sar.rejected")
        expect(data_request_title).to eq("Create a rejected offender sar")

      end
    end
  end
end

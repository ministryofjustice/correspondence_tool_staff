require "rails_helper"

describe CommissioningEmailPersonalisation do
  let(:offender_sar_case) { create(:offender_sar_case, subject_full_name: "Subject name") }
  let(:data_request_area) { create(:data_request_area, offender_sar_case:) }
  let(:commissioning_document) { create :commissioning_document, data_request_area: }
  let(:kase) { create :offender_sar_case }
  let(:email_address) { "test@test.com" }
  let(:personalisation) do
    described_class.new(
      commissioning_document,
      kase.number,
      email_address,
    )
  end

  describe "#initialize" do
    it "requires commissioning document, case and recipient" do
      expect(personalisation.kase_number).to eq kase.number
      expect(personalisation.recipient).to eq email_address
      expect(personalisation.commissioning_document).to eq commissioning_document.decorate
    end
  end

  describe "#personalise" do
    it "returns a hash with personalisation values" do
      expect(personalisation.personalise).to include(
        email_subject: "Subject Access Request - 250129004 - Day 1 commissioning - Subject name",
        email_address: "test@test.com",
        deadline_text: "The information is required in Branston no later than #{commissioning_document.deadline}.",
        link_to_file: kind_of(Hash),
      )
    end
  end
end

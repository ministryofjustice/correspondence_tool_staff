require "rails_helper"

describe RespondedCaseValidator do
  let(:foi)   { create(:foi_case) }
  let(:ico)   { create(:ico_foi_case, original_case: foi) }

  context "not prepared for respond" do
    it "does not validate" do
      expect_any_instance_of(described_class).not_to receive(:validate_responded_date)
      ico.valid?
    end
  end

  context "prepared for respond" do
    before { ico.prepare_for_respond }

    context "no date" do
      it "is not valid" do
        ico.date_responded = nil
        expect(ico).not_to be_valid
        expect(ico.errors[:date_responded]).to eq ["cannot be blank"]
      end
    end

    context "impossible date assigned" do
      it "is not valid" do
        ico.update!(date_responded_dd: "", date_responded_mm: "12", date_responded_yyyy: "2018")
        expect(ico).not_to be_valid
        expect(ico.errors[:date_responded]).to include("Invalid date")
      end
    end

    context "before date received" do
      it "is not valid" do
        ico.date_responded = ico.received_date - 1.day
        expect(ico).not_to be_valid
        expect(ico.errors[:date_responded]).to eq ["cannot be before date received"]
      end
    end

    context "in future" do
      it "is not valid" do
        ico.date_responded = 1.day.from_now.to_date
        expect(ico).not_to be_valid
        expect(ico.errors[:date_responded]).to eq ["cannot be in the future"]
      end
    end
  end

  context "valid date" do
    it "is valid" do
      ico.date_responded = Time.zone.today
      expect(ico).to be_valid
    end
  end
end

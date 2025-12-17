require "rails_helper"

RSpec.describe BankHolidays do
  describe "#get_bank_holidays_for" do
    subject(:bank_holidays) { described_class.new(division) }

    before do
      allow(Net::HTTP).to receive(:get).with(URI("https://www.gov.uk/bank-holidays.json"))
                                       .and_return(File.read("spec/fixtures/bank_holidays_response.json"))
    end

    context "when division is 'england-and-wales'" do
      let(:division) { "england-and-wales" }

      it "returns 'england-and-wales' holidays" do
        expect(bank_holidays.get_bank_holidays_for(division)).to eq(JSON.parse(File.read("spec/fixtures/bank_holidays_response.json"))[division]["events"])
      end
    end

    context "when division is 'scotland'" do
      let(:division) { "scotland" }

      it "returns 'scotland' holidays" do
        expect(bank_holidays.get_bank_holidays_for(division)).to eq(JSON.parse(File.read("spec/fixtures/bank_holidays_response.json"))[division]["events"])
      end
    end

    context "when division is 'northern-ireland'" do
      let(:division) { "northern-ireland" }

      it "returns 'northern-ireland' holidays" do
        expect(bank_holidays.get_bank_holidays_for(division)).to eq(JSON.parse(File.read("spec/fixtures/bank_holidays_response.json"))[division]["events"])
      end
    end
  end
end

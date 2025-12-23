require "rails_helper"

RSpec.describe BankHolidays do
  let(:fixture_data) { File.read("spec/fixtures/bank_holidays_response.json") }
  let(:parsed_data) { JSON.parse(fixture_data) }
  let(:bank_holidays) { described_class.new }

  before do
    allow(Net::HTTP).to receive(:get)
                          .with(URI("https://www.gov.uk/bank-holidays.json"))
                          .and_return(fixture_data)
  end

  describe "#get_bank_holidays_for" do
    %w[england-and-wales scotland northern-ireland].each do |division|
      puts division
      context "when division is '#{division}'" do
        it "returns '#{division}' holidays" do
          puts division
          expect(bank_holidays).to eq(parsed_data[division]["events"])
          puts bank_holidays
        end
      end
    end
  end
end

require "rails_helper"

RSpec.describe Holidays::BankHolidays do
  describe "#get_bank_hols" do
    let(:region) { "england-and-wales" }
    let(:service) { described_class.new }
    let(:url) { Holidays::BankHolidays::URL }


    it "returns bank holidays for a region from the UK government API" do
      response = { "england-and-wales" => { "events" => [{ "title" => "Christmas Day", "date" => "2025-12-25" }] } }
      allow(HTTParty).to receive(:get).with(url).and_return(response)
      data = HTTParty.get(url)
      expect(data["england-and-wales"]["events"]).to include({ "title" => "Christmas Day", "date" => "2025-12-25" })
    end

    it "updates the cache when expired" do
      first_response = { region => { "events" => [{ "title" => "Christmas Day", "date" => "2025-12-25" }] } }
      second_response = { region => { "events" => [{ "title" => "Boxing Day", "date" => "2025-12-26" }] } }

      allow(Net::HTTP).to receive(:get).and_return(first_response.to_json)
      events = service.get_bank_hols(region)
      expect(events).to include({ "title" => "Christmas Day", "date" => "2025-12-25" })


      Rails.cache.clear
      allow(Net::HTTP).to receive(:get).and_return(second_response.to_json)
      events = service.get_bank_hols(region)
      expect(events).to include({ "title" => "Boxing Day", "date" => "2025-12-26" })
    end
  end
end

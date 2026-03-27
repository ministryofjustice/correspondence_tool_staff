require "rails_helper"

RSpec.describe BankHolidaysHelper, type: :helper do
  let(:bank_holiday_data) do
    JSON.parse File.read(Rails.root.join("spec/fixtures/bank_holidays_response_truncated.json"))
  end

  describe "#bank_holidays_summary" do
    let(:bank_holiday) do
      instance_double(BankHoliday, data: bank_holiday_data)
    end

    it "returns an array of regions and total number of holidays" do
      expect(bank_holidays_summary(bank_holiday)).to match_array([%w[england-and-wales scotland northern-ireland], 9])
    end
  end

  describe "#bank_holidays_for_region" do
    context "with valid data" do
      let(:bank_holiday) do
        instance_double(BankHoliday, data: bank_holiday_data)
      end

      it "returns sorted holidays for the specified region with valid dates first" do
        expect(bank_holidays_for_region(bank_holiday, "northern-ireland")).to eq(
          [
            { "date" => "2026-01-01", "title" => "New Year's Day", "notes" => "", "bunting" => true },
            { "date" => "2026-03-17", "title" => "St Patrick's Day", "notes" => "", "bunting" => true },
            { "date" => "2026-07-13", "title" => "Battle of the Boyne (Orangemen's Day)", "notes" => "Substitute day", "bunting" => false },
          ],
        )
      end
    end

    context "with invalid data" do
      let(:bank_holiday) do
        bank_holiday_data["northern-ireland"].merge!(
          "division": "northern-ireland",
          "events" => [
            { "date" => "invalid-date", "title" => "Invalid Date Holiday", "notes" => "", "bunting" => true },
            { "date" => "2026-03-17", "title" => "St Patrick's Day", "notes" => "", "bunting" => true },
            { "date" => "2026-07-13", "title" => "Battle of the Boyne (Orangemen's Day)", "notes" => "Substitute day", "bunting" => false },
            { "date" => nil, "title" => "Nil Date Holiday", "notes" => "", "bunting" => true },
            { "date" => "2026-01-01", "title" => "New Year's Day", "notes" => "", "bunting" => true },
          ],
        )

        instance_double(BankHoliday, data: bank_holiday_data)
      end

      it "puts invalid dates to the top of the list" do
        expect(bank_holidays_for_region(bank_holiday, "northern-ireland")).to eq(
          [
            { "date" => "invalid-date", "title" => "Invalid Date Holiday", "notes" => "", "bunting" => true },
            { "date" => nil, "title" => "Nil Date Holiday", "notes" => "", "bunting" => true },
            { "date" => "2026-01-01", "title" => "New Year's Day", "notes" => "", "bunting" => true },
            { "date" => "2026-03-17", "title" => "St Patrick's Day", "notes" => "", "bunting" => true },
            { "date" => "2026-07-13", "title" => "Battle of the Boyne (Orangemen's Day)", "notes" => "Substitute day", "bunting" => false },
          ],
        )
      end

      it "returns an empty array if the region is not found in data" do
        expect(bank_holidays_for_region(bank_holiday, "wales")).to eq([])
      end
    end
  end
end

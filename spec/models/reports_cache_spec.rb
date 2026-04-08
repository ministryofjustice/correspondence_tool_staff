require "rails_helper"

RSpec.describe ReportsCache, type: :model do
  describe ".latest_for" do
    it "returns the most recently created cache for a report type" do
      described_class.create!(report_type: "R005", data: { a: 1 })
      newer = described_class.create!(report_type: "R005", data: { a: 2 })
      described_class.create!(report_type: "R105", data: { a: 3 })

      expect(described_class.latest_for("R005")).to eq(newer)
    end
  end
end

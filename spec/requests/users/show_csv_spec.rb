require "rails_helper"

describe "GET /users/:id.csv" do
  include Devise::Test::IntegrationHelpers

  let(:manager) { find_or_create :disclosure_bmt_user }

  before { sign_in manager }

  it "returns the csv file in the body" do
    Timecop.freeze Time.zone.local(2018, 11, 9, 13, 48, 22) do
      get user_path(manager, format: :csv)

      expect(response).to be_successful
      expect(response.headers["Content-Disposition"])
        .to eq 'attachment; filename="disclosure-bmt_managing_user-cases-18-11-09-134822.csv"'
      expect(response.headers["Content-Type"]).to eq "text/csv; charset=utf-8"
      expect(response.body).to include(CSV.generate_line(CSVExporter::CSV_COLUMN_HEADINGS))
    end
  end
end

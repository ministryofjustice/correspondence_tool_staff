require "rails_helper"

describe "GET /cases/closed.csv" do
  include Devise::Test::IntegrationHelpers

  let(:manager) { find_or_create :disclosure_specialist_bmt }

  before do
    create(:closed_case)
    sign_in manager
  end

  it "returns 200" do
    get closed_filter_path(format: :csv)
    expect(response.status).to eq 200
  end

  it "generates a file and downloads it" do
    get closed_filter_path(format: :csv)
    expect(response.headers["Content-Disposition"]).to include(".csv")
    expect(response.body).to include(CSV.generate_line(CSVExporter::CSV_COLUMN_HEADINGS))
  end

  it "does not paginate the result set" do
    get closed_filter_path(format: :csv)
    expect(response.body.split("\n").length).to be > 1
  end
end

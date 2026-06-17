require "rails_helper"

describe "GET /cases/my_open.csv" do
  include Devise::Test::IntegrationHelpers
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }

  before { sign_in disclosure_specialist }

  it "downloads a csv file" do
    allow(CSVGenerator).to receive(:filename).with("my-open").and_return("abc.csv")

    get my_open_filter_path(tab: "in_time", format: :csv)
    expect(response.status).to eq 200
    expect(response.headers["Content-Disposition"]).to eq 'attachment; filename="abc.csv"'
    expect(response.body).to eq CSV.generate_line(CSVExporter::CSV_COLUMN_HEADINGS)
  end
end

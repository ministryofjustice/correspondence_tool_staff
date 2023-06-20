require "rails_helper"

describe "stats/new.html.slim", type: :view do
  let(:report_1) do
    instance_double ReportType,
                    id: 1,
                    full_name: "Report 1"
  end
  let(:report_2) do
    instance_double ReportType,
                    id: 2,
                    full_name: "Report 2"
  end
  let(:reports) { [report_1, report_2] }
  let(:new_report) { Report.new }

  let!(:page) do
    assign(:report, new_report)
    assign(:custom_reports_foi, reports)
    assign(:custom_reports_sar, reports)
    assign(:custom_reports_offender_sar, reports)
    assign(:custom_reports_offender_sar_complaint, reports)
    assign(:custom_reports_closed_cases, reports)
    assign(:correspondence_types, [
      CorrespondenceType.foi,
      CorrespondenceType.sar,
      CorrespondenceType.offender_sar,
      StatsController.closed_cases_correspondence_type,
    ])

    render
    stats_new_page.load(rendered)
    stats_new_page
  end

  context "when valid page" do
    it "has a heading" do
      expect(page.page_heading.heading.text).to eq "Create custom report"
      expect(page.page_heading).to have_no_sub_heading
    end

    it "has a list of custom reports" do
      expect(page.options_foi.reports.size).to eq reports.size
      expect(page.options_sar.reports.size).to eq reports.size
      expect(page.options_closed_cases.reports.size).to eq reports.size
    end

    it "has a start/end date" do
      expect(page).to have_period_start
      expect(page).to have_period_end
    end

    it "has a submit button" do
      expect(page).to have_submit_button
    end
  end
end

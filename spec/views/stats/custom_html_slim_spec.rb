require 'rails_helper'

describe 'stats/custom.html.slim', type: :view do
  let(:report_1)      { instance_double ReportType,
                                        id: 1,
                                        full_name: "Report 1" }
  let(:report_2)      { instance_double ReportType,
                                        id: 2,
                                        full_name: "Report 2" }
  let(:reports){ [ report_1, report_2 ]  }

  let(:new_report) { Report.new }

  it 'has a heading' do
    assign(:report, new_report)
    assign(:custom_reports, reports)

    render
    stats_custom_page.load(rendered)

    page = stats_custom_page
    expect(page.page_heading.heading.text).to eq "Create custom report"
    expect(page.page_heading).to have_no_sub_heading

    expect(page.report_types.report.size).to eq reports.size

  end

  it 'has a list of custom reports' do
    assign(:report, new_report)
    assign(:custom_reports, reports)

    render
    stats_custom_page.load(rendered)

    page = stats_custom_page

    expect(page.report_types.report.size).to eq reports.size
  end

  it 'has a start/end date' do
    assign(:report, new_report)
    assign(:custom_reports, reports)

    render
    stats_custom_page.load(rendered)

    page = stats_custom_page
    expect(page).to have_period_start
    expect(page).to have_period_end
  end

  it 'has a submit button' do
    assign(:report, new_report)
    assign(:custom_reports, reports)

    render
    stats_custom_page.load(rendered)

    page = stats_custom_page

    expect(page).to have_submit_button
  end
end

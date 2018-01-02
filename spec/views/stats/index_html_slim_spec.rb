require 'rails_helper'

describe 'stats/index.html.slim', type: :view do
  let(:report_1)      { instance_double ReportType,
                                        id: 1,
                                        full_name: "Report 1" }
  let(:report_2)      { instance_double ReportType,
                                        id: 2,
                                        full_name: "Report 2" }
  let(:reports){ [ report_1, report_2 ]  }


  it 'has a heading' do
    assign(:reports, reports)
    render
    stats_index_page.load(rendered)

    page = stats_index_page
    expect(page.page_heading.heading.text).to eq "Statistics"
    expect(page.page_heading).to have_no_sub_heading
  end


  it 'has a table with a list of reports' do
    assign(:reports, reports)
    render
    stats_index_page.load(rendered)

    page = stats_index_page
    expect(page.report_caption.text).to eq 'Reports for this year'

    page.reports.each_with_index  do | report, index |
      expect(report.name.text).to eq reports[index].full_name

      expect(report.action_column).to have_link("Download #{reports[index].full_name}",
                               href: stats_download_path(id: reports[index].id))

    end


  end


end

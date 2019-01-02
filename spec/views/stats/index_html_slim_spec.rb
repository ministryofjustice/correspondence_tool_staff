require 'rails_helper'

describe 'stats/index.html.slim', type: :view do
  let(:report_1)      { build_stubbed :report_type, :r004 }
  let(:report_2)      { build_stubbed :report_type, :r005 }

  let(:report_3)      { build_stubbed :r105_report_type}
  let(:report_4)      { instance_double ReportType,
                                        id: 2,
                                        full_name: "Report 4" }
  let(:foi_reports)   { [ report_1, report_2 ]  }
  let(:sar_reports)   { [ report_3 ]  }
  let(:today)         { Date.today.strftime(Settings.default_date_format) }
  let(:year_start)    { Date.new(2019, 1, 1).strftime(Settings.default_date_format) }

  it 'has a heading' do
    assign(:foi_reports, foi_reports)
    assign(:sar_reports, sar_reports)
    render
    stats_index_page.load(rendered)

    page = stats_index_page
    expect(page.page_heading.heading.text).to eq "Performance reports"
    expect(page.page_heading).to have_no_sub_heading
  end


  context 'displaying list of reports per type' do
    context 'FOI' do
      it 'has a list of FOI reports' do
        assign(:foi_reports, foi_reports)
        assign(:sar_reports, sar_reports)
        render
        stats_index_page.load(rendered)

        page = stats_index_page

        expect(page.foi.type_name.text).to eq 'Standard FOI reports'

        page.foi.reports.each_with_index  do | report, index |
          expect(report.name.text).to eq foi_reports[index].full_name
          if index == 0
            expect(report.description.text)
                .to eq "Includes performance data about how we are meeting statutory deadlines and how we are using exemptions."
          else
            expect(report.description.text)
                .to eq 'Includes performance data about FOI requests we received and responded to from the beginning of the year by month.'
          end

          expect(report.report_period.text).to eq "Reporting period: #{year_start} to #{today}"
          expect(report.download).to have_link("Download report - #{foi_reports[index].full_name}",  href: stats_download_path(id: foi_reports[index].id))
        end
      end
    end

    context 'SAR' do
      it 'has a list of SAR reports' do
        assign(:foi_reports, foi_reports)
        assign(:sar_reports, sar_reports)
        render
        stats_index_page.load(rendered)

        page = stats_index_page

        expect(page.sar.type_name.text).to eq 'Standard SAR reports'

        page.sar.reports.each_with_index  do | report, index |
          expect(report.name.text).to eq sar_reports[index].full_name
          expect(report.description.text)
              .to eq "Includes performance data about SAR requests we received and responded to from the beginning of the year by month."

          expect(report.report_period.text).to eq "Reporting period: #{year_start} to #{today}"
          expect(report.download).to have_link("Download report - #{sar_reports[index].full_name}",  href: stats_download_path(id: sar_reports[index].id))
        end
      end
    end
  end

end

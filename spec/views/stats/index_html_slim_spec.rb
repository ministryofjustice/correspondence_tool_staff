require 'rails_helper'

describe 'stats/index.html.slim', type: :view do
  let!(:time) { Time.local(2018, 10, 3) }

  let(:available_reports) {
    {
      foi: foi_reports,
      sar: sar_reports,
      offender_sar: offender_sar_reports,
    }
  }

  let(:foi_reports) {
    [
      build_stubbed(:report_type, :r004),
      build_stubbed(:report_type, :r005)
    ]
  }

  let(:sar_reports) {
    [
      build_stubbed(:report_type, :r105)
    ]
  }

  let(:offender_sar_reports) {
    [
      build_stubbed(:report_type, :r205)
    ]
  }

  let!(:year_to_date_period) do
    Timecop.freeze(time) do
      {
        start_date: Date.new(2018, 1, 1).strftime(Settings.default_date_format),
        end_date: Date.current.strftime(Settings.default_date_format)
      }
    end
  end

  let!(:page) do
    Timecop.freeze(time) do
      assign(:reports, available_reports)

      render
      stats_index_page.load(rendered)
      stats_index_page
    end
  end

  describe 'contents' do
    context 'for heading' do
      it 'is present' do
        expect(page.page_heading.heading.text).to eq 'Performance reports'
      end

      it 'has no subheading' do
        expect(page.page_heading).to have_no_sub_heading
      end
    end

    context 'for FOI reports' do
      it 'is present' do
        expected_content(
          page_section: page.foi,
          title: 'Standard FOI reports',
          date_period: year_to_date_period,
          reports: foi_reports
        )
      end
    end

    context 'for SAR reports' do
      it 'is present' do
        expected_content(
          page_section: page.sar,
          title: 'Standard SAR reports',
          date_period: year_to_date_period,
          reports: sar_reports
        )
      end
    end

    context 'for Offender SAR reports' do
      it 'is present' do
        expected_content(
          page_section: page.offender_sar,
          title: 'Offender SAR reports',
          date_period: year_to_date_period,
          reports: offender_sar_reports
        )
      end
    end
  end

  # Generic testing of each reporting section which also aids
  # consistency of output.
  #
  # +date_period+ is a Hash of :start_date and :end_date
  # +reports+ is the collection of ReportType presented in that section
  def expected_content(page_section:, title:, date_period:, reports: [])
    expect(page_section.type_name.text).to eq title

    page_section.reports.each_with_index  do |report, index|
      reporting_period = [
        "Reporting period:",
        "#{date_period[:start_date]}",
        "to #{date_period[:end_date]}"
      ].join(' ')

      download_text = "Download report - #{reports[index].full_name}"
      report_link = stat_path(id: reports[index].id)

      expect(report.name.text).to eq reports[index].full_name
      expect(report.report_period.text).to eq reporting_period
      expect(report.download).to have_link(download_text,  href: report_link)
    end
  end
end

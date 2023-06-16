class PopulateNewReportTypeColumns < ActiveRecord::DataMigration
  def up
    attrs = {
      "R002" => {
        standard_report: false,
        default_reporting_period: "year_to_date",
      },
      "R003" => {
        standard_report: true,
        default_reporting_period: "quarter_to_date",
      },
      "R004" => {
        standard_report: true,
        default_reporting_period: "year_to_date",
      },
      "R005" => {
        standard_report: true,
        default_reporting_period: "year_to_date",
      },
      "R006" => {
        standard_report: true,
        default_reporting_period: "year_to_date",
      },
      "R102" => {
        standard_report: true,
        default_reporting_period: "year_to_date",
      },
      "R103" => {
        standard_report: true,
        default_reporting_period: "quarter_to_date",
      },
      "R105" => {
        standard_report: false,
        default_reporting_period: "year_to_date",
      },
    }

    attrs.each do |report_abbreviation, new_values|
      rt = ReportType.find_by!(abbr: report_abbreviation)
      rt.update!(new_values)
    end
  end
  # rubocop:enable Metrics/MethodLength
end

class UpdateStandardReportsAndRenameReports < ActiveRecord::DataMigration
  def up
    attrs = {
      "R002" => {
        full_name: "Appeals report",
        standard_report: false,
      },
      "R003" => {
        standard_report: false,
      },
      "R006" => {
        standard_report: false,
      },
      "R102" => {
        standard_report: false,
        full_name: "Appeals performance report",
      },
      "R103" => {
        standard_report: false,
        full_name: "Business unit report",
      },
      "R105" => {
        standard_report: true,
      },
    }

    attrs.each do |report_abbreviation, new_values|
      rt = ReportType.find_by!(abbr: report_abbreviation)
      rt.update!(new_values)
    end
  end
end

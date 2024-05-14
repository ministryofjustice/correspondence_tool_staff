class PopulateFOISARReportTypes < ActiveRecord::DataMigration
  def up
    ReportType.reset_column_information
    attrs = {
      "R002" => {
        foi: true,
        sar: false,
      },
      "R003" => {
        foi: true,
        sar: false,
      },
      "R004" => {
        foi: true,
        sar: false,
      },
      "R005" => {
        foi: true,
        sar: false,
      },
      "R006" => {
        foi: false,
        sar: false,
      },
      "R103" => {
        foi: false,
        sar: true,
      },
    }
    attrs.each do |report_abbreviation, new_values|
      rt = ReportType.find_by!(abbr: report_abbreviation)
      rt.update!(new_values)
    end
  end
end

class AddSarAppealsReport < ActiveRecord::DataMigration
  def up
    ReportType.reset_column_information

    rt = ReportType.find_by(abbr: "R102")
    rt = ReportType.new if rt.nil?
    rt.update!(
      abbr: "R102",
      full_name: "Appeals performance report(SARs)",
      class_name: "Stats::R102SarAppealsPerformanceReport",
      custom_report: true,
      foi: false,
      sar: true,
      seq_id: 320,
    )
  end
end

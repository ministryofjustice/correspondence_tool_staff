class UpdateCabinetOfficeStatsToBeCustom < ActiveRecord::DataMigration
  def up
    rt = ReportType.find_by_abbr("R004")
    raise "Unbable to find report type R004" if rt.nil?

    rt.update! custom_report: true
  end
end

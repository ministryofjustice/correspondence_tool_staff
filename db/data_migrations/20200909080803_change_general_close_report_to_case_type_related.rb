class ChangeGeneralCloseReportToCaseTypeRelated < ActiveRecord::DataMigration
  def up
    rt = ReportType.find_by(abbr: 'R007')
    if !rt.nil?
      rt.update(
        custom_report: false,
        foi: true,
        sar: true,
        offender_sar: false)
    end 
  end

  def down
    rt = ReportType.find_by(abbr: 'R007')
    if !rt.nil?
      rt.update(
        custom_report: true,
        foi: false,
        sar: false,
        offender_sar: false)
    end 
  end 
end
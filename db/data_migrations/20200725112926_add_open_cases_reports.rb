class AddOpenCasesReports < ActiveRecord::DataMigration
  def up
    rt = ReportType.find_by(abbr: 'R201')
    rt = ReportType.new if rt.nil?
    rt.update(
        abbr: 'R301',
        full_name: 'Open cases report for Offender Sar',
        class_name: 'Stats::R301OffenderSarOpenCasesReport',
        custom_report: false,
        foi: false,
        sar: false,
        offender_sar: true,
        seq_id: 700)

    rt = ReportType.find_by(abbr: 'R200')
    rt = ReportType.new if rt.nil?
    rt.update(
        abbr: 'R300',
        full_name: 'Open cases report',
        class_name: 'Stats::R300GeneralOpenCasesReport',
        custom_report: false,
        foi: true,
        sar: true,
        offender_sar: false,
        seq_id:800)
    
  end
end
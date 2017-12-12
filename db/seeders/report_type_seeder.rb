class ReportTypeSeeder

  def seed!(verbose=false)
    puts '----Seeding Report Types ----' if verbose

    ReportType.find_or_create_by!(abbr:'R002', full_name: 'Appeals performance report', class_name: 'Stats::R002AppealsPerformanceReport' , custom_report: true, seq_id: 100)
    ReportType.find_or_create_by!(abbr:'R003', full_name: 'Business unit report', class_name: 'Stats::R003BusinessUnitPerformanceReport' , custom_report: true, seq_id: 200)
    ReportType.find_or_create_by!(abbr:'R004', full_name: 'Cabinet Office report', class_name: 'Stats::R004CabinetOfficeReport', custom_report: false, seq_id: 400)
    ReportType.find_or_create_by!(abbr:'R005', full_name: 'Monthly report', class_name: 'Stats::R005MonthlyPerformanceReport',custom_report: true, seq_id: 300)
  end
end


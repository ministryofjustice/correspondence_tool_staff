class ReportTypeSeeder

  def seed!(verbose=false)
    puts '----Seeding Report Types ----' if verbose

    ReportType.find_or_create_by!(abbr:'R002', full_name: 'Appeals performance report', class_name: 'Stats::R002AppealsPerformanceReport' , custom_report: true, seq_id: 100)
    ReportType.find_or_create_by!(abbr:'R003', full_name: 'Business unit report', class_name: 'Stats::R003BusinessUnitPerformanceReport' , custom_report: true, seq_id: 200)
    ReportType.find_or_create_by!(abbr:'R004', full_name: 'Cabinet Office report', class_name: 'Stats::R004CabinetOfficeReport', custom_report: false, seq_id: 400)
    ReportType.find_or_create_by!(abbr:'R005', full_name: 'Monthly report', class_name: 'Stats::R005MonthlyPerformanceReport',custom_report: true, seq_id: 300)
    ReportType.find_or_create_by!(abbr:'R006', full_name: 'Business unit map', class_name: 'Stats::R006KiloMap', custom_report: false, seq_id: 9999)
  end

  def create_or_update!(attrs)
    rt = ReportType.find_by_abbr(attrs[:abbr])
    rt = ReportType.new if rt.nil?

    rt.update!(attrs)
  end

  def seed!(verbose=false)
    attrs = {abbr:'R002',
            full_name: 'Appeals performance report',
            class_name: 'Stats::R002AppealsPerformanceReport',
            custom_report: true,
            foi: true,
            sar: false,
            seq_id: 100}
    create_or_update!(attrs)

    attrs = {abbr:'R003',
             full_name: 'Business unit report',
             class_name: 'Stats::R003BusinessUnitPerformanceReport' ,
             custom_report: true,
             foi: true,
             seq_id: 200}
    create_or_update!(attrs)

    attrs = {abbr:'R004',
            full_name: 'Cabinet Office report',
            class_name: 'Stats::R004CabinetOfficeReport',
            custom_report: true,
            foi: true,
            seq_id: 400}
            create_or_update!(attrs)

      attrs = {abbr:'R005',
              full_name: 'Monthly report',
              class_name: 'Stats::R005MonthlyPerformanceReport',
              custom_report: true,
              foi: true,
              sar: true,
              seq_id: 300}
      create_or_update!(attrs)

      attrs = {abbr:'R006',
              full_name: 'Business unit map',
              class_name: 'Stats::R006KiloMap',
              custom_report: false,
              foi: true,
              sar: true,
              seq_id: 9999}
      create_or_update!(attrs)

      attrs = {abbr: 'R103',
              full_name: 'Business unit report (SARs)',
              class_name: 'Stats::R103SarBusinessUnitPerformanceReport',
              custom_report: true,
              foi: false,
              sar:true,
              seq_id: 250}
      create_or_update!(attrs)
  end
end

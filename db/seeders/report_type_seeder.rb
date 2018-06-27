class ReportTypeSeeder

  def create_or_update!(attrs)
    rt = ReportType.find_by_abbr(attrs[:abbr])
    rt = ReportType.new if rt.nil?

    rt.update!(attrs)
  end

  #rubocop:disable Metrics/MethodLength
  #rubocop:disable Metrics/CyclomaticComplexity
  def seed!(verbose: false)
    attrs = {abbr:'R002',
            full_name: 'Appeals performance report',
            class_name: 'Stats::R002AppealsPerformanceReport',
            custom_report: true,
            foi: true,
            sar: false,
            seq_id: 100}
    create_or_update!(attrs)
    puts 'Created report R002' if verbose

    attrs = {abbr:'R003',
             full_name: 'Business unit report',
             class_name: 'Stats::R003BusinessUnitPerformanceReport' ,
             custom_report: true,
             foi: true,
             sar: false,
             seq_id: 200}
    create_or_update!(attrs)
    puts 'Created report R003' if verbose


    attrs = {abbr:'R004',
             full_name: 'Cabinet Office report',
             class_name: 'Stats::R004CabinetOfficeReport',
             custom_report: true,
             foi: true,
             sar: false,
             seq_id: 400}
    create_or_update!(attrs)
    puts 'Created report R004' if verbose


    attrs = {abbr:'R005',
            full_name: 'Monthly report',
            class_name: 'Stats::R005MonthlyPerformanceReport',
            custom_report: true,
            foi: true,
            sar: false,
            seq_id: 300}
    create_or_update!(attrs)
    puts 'Created report R005' if verbose

    attrs = {abbr:'R006',
            full_name: 'Business unit map',
            class_name: 'Stats::R006KiloMap',
            custom_report: false,
            foi: true,
            sar: false,
            seq_id: 9999}
    create_or_update!(attrs)
    puts 'Created report R006' if verbose

    attrs = {abbr: 'R103',
            full_name: 'Business unit report (SARs)',
            class_name: 'Stats::R103SarBusinessUnitPerformanceReport',
            custom_report: true,
            foi: false,
            sar:true,
            seq_id: 250}
    create_or_update!(attrs)
    puts 'Created report R103' if verbose
  end
  #rubocop:enable Metrics/MethodLength
  #rubocop:enable Metrics/CyclomaticComplexity
end

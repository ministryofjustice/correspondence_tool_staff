class ReportTypeSeeder

  def create_or_update!(attrs)
    rt = ReportType.find_by_abbr(attrs[:abbr])
    rt = ReportType.new if rt.nil?

    rt.update!(attrs)
  end

  ATTRS_LIST = [{abbr:'R002',
                 full_name: 'Appeals performance report',
                 class_name: 'Stats::R002AppealsPerformanceReport',
                 custom_report: true,
                 seq_id: 100},
                {abbr:'R003',
                         full_name: 'Business unit report',
                         class_name: 'Stats::R003BusinessUnitPerformanceReport' ,
                         custom_report: true,
                         seq_id: 200},
                {abbr:'R004',
                         full_name: 'Cabinet Office report',
                         class_name: 'Stats::R004CabinetOfficeReport',
                         custom_report: true,
                         seq_id: 400},
                {abbr:'R005',
                         full_name: 'Monthly report',
                         class_name: 'Stats::R005MonthlyPerformanceReport',
                         custom_report: true,
                         seq_id: 300},
                {abbr: 'R105',
                         full_name: 'Monthly report (SARs)',
                         class_name: 'Stats::R105SarMonthlyPerformanceReport',
                         custom_report: false,
                         seq_id: 310},
                {abbr:'R006',
                         full_name: 'Business unit map',
                         class_name: 'Stats::R006KiloMap',
                         custom_report: false,
                         seq_id: 9999},
                {abbr: 'R103',
                         full_name: 'Business unit report',
                         class_name: 'Stats::R103SarBusinessUnitPerformanceReport',
                         custom_report: true,
                         seq_id: 250},
  ]

  def seed!(verbose: false)
    puts '----Seeding ReportTypes----' if verbose
    ATTRS_LIST.each do |attrs|
      create_or_update!(attrs)
      puts "    Created report #{attrs[:abbr]}" if verbose
    end
  end
end

class ReportTypeSeeder
  def create_or_update!(attrs)
    rt = ReportType.find_by_abbr(attrs[:abbr])
    rt = ReportType.new if rt.nil?

    rt.update!(attrs)
  end

  ATTRS_LIST = [{ abbr: "R002",
                  full_name: "Appeals performance report",
                  class_name: "Stats::R002AppealsPerformanceReport",
                  custom_report: true,
                  seq_id: 100 },
                { abbr: "R003",
                  full_name: "Business unit report",
                  class_name: "Stats::R003BusinessUnitPerformanceReport",
                  custom_report: true,
                  seq_id: 200 },
                { abbr: "R004",
                  full_name: "Cabinet Office report",
                  class_name: "Stats::R004CabinetOfficeReport",
                  custom_report: true,
                  seq_id: 400 },
                { abbr: "R005",
                  full_name: "Monthly report",
                  class_name: "Stats::R005MonthlyPerformanceReport",
                  custom_report: true,
                  standard_report: true,
                  foi: true,
                  sar: false,
                  offender_sar: false,
                  seq_id: 300 },
                { abbr: "R105",
                  full_name: "Monthly report (SARs)",
                  class_name: "Stats::R105SARMonthlyPerformanceReport",
                  custom_report: false,
                  standard_report: true,
                  foi: false,
                  sar: true,
                  offender_sar: false,
                  seq_id: 310 },
                { abbr: "R006",
                  full_name: "Business unit map",
                  class_name: "Stats::R006KiloMap",
                  custom_report: false,
                  seq_id: 9999 },
                { abbr: "R007",
                  full_name: "Closed cases report",
                  class_name: "Stats::R007ClosedCasesReport",
                  custom_report: false,
                  standard_report: false,
                  foi: true,
                  sar: true,
                  seq_id: 500,
                  default_reporting_period: "last_month" },
                { abbr: "R103",
                  full_name: "Business unit report",
                  class_name: "Stats::R103SARBusinessUnitPerformanceReport",
                  custom_report: true,
                  seq_id: 250 },
                { abbr: "R205",
                  full_name: "Monthly report (Offender SARs)",
                  class_name: "Stats::R205OffenderSARMonthlyPerformanceReport",
                  custom_report: false,
                  standard_report: true,
                  foi: false,
                  sar: false,
                  offender_sar: true,
                  seq_id: 600,
                  default_reporting_period: "year_to_date",
                  etl: false },
                { abbr: "R206",
                  full_name: "Monthly report (Complaint - Standard)",
                  class_name: "Stats::R206OffenderStandardComplaintMonthlyPerformanceReport",
                  custom_report: true,
                  standard_report: true,
                  foi: false,
                  sar: false,
                  offender_sar: false,
                  seq_id: 1200,
                  default_reporting_period: "year_to_date",
                  offender_sar_complaint: true,
                  etl: false },
                { abbr: "R207",
                  full_name: "Monthly report (Complaint - ICO)",
                  class_name: "Stats::R207OffenderICOComplaintMonthlyPerformanceReport",
                  custom_report: true,
                  standard_report: true,
                  foi: false,
                  sar: false,
                  offender_sar: false,
                  seq_id: 1300,
                  default_reporting_period: "year_to_date",
                  offender_sar_complaint: true,
                  etl: false },
                { abbr: "R208",
                  full_name: "Monthly report (Complaint - Litigation)",
                  class_name: "Stats::R208OffenderLitigationComplaintMonthlyPerformanceReport",
                  custom_report: true,
                  standard_report: true,
                  foi: false,
                  sar: false,
                  offender_sar: false,
                  seq_id: 1400,
                  default_reporting_period: "year_to_date",
                  offender_sar_complaint: true,
                  etl: false },
                { abbr: "R901",
                  full_name: "Open cases report for Offender SAR",
                  class_name: "Stats::R901OffenderSARCasesReport",
                  custom_report: false,
                  standard_report: false,
                  foi: false,
                  sar: false,
                  offender_sar: true,
                  seq_id: 1100 },
                { abbr: "R900",
                  full_name: "Cases report",
                  class_name: "Stats::R900CasesReport",
                  custom_report: false,
                  standard_report: false,
                  foi: true,
                  sar: true,
                  offender_sar: false,
                  seq_id: 1000 }].freeze

  def seed!(verbose: false)
    Rails.logger.debug "----Seeding ReportTypes----" if verbose
    ATTRS_LIST.each do |attrs|
      create_or_update!(attrs)
      Rails.logger.debug "    Created report #{attrs[:abbr]}" if verbose
    end
  end
end

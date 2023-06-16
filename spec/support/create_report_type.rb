def create_report_type(abbr:, **options)
  report_type = nil

  begin
    unless (report_type = ReportType.find_by(abbr: abbr.upcase))
      report_type = find_or_create :report_type, abbr: abbr.upcase, **options
    end
  rescue StandardError
    report_type = find_or_create :report_type, abbr.to_sym, **options
  end

  report_type
end

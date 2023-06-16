namespace :reports do
  task r003: :environment do
    report = Stats::R003BusinessUnitPerformanceReport.new
    report.run
    x = report.to_csv
    ap x
  end

  desc "produce audit report"
  task :audit, %i[start_date end_date] => :environment do |_task, args|
    report = Stats::Audit.new(Date.parse(args[:start_date]), Date.parse(args[:end_date]))
    report.run
    puts "report generated: #{report.filename}"
  end
end

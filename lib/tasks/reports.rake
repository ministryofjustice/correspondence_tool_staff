namespace :reports do
  task :r003 => :environment do
    report = Stats::R003BusinessUnitPerformanceReport.new
    report.run
    x = report.to_csv
    ap x
  end

  task :audit => :environment do
    report = Stats::Audit.new(Date.new(2017,10,1), Date.new(2017,10,31))
    report.run
    puts "report generated: #{report.filename}"
  end
end

namespace :reports do
  task :r003 => :environment do
    report = Stats::R003BusinessUnitPerformanceReport.new
    report.run
    x = report.to_csv
    ap x
  end
end
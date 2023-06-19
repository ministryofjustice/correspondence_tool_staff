desc "run Smoke tests"

task smoke: :environment do
  require Rails.root.join("lib/smoketest")

  smokey = Smoketest.new
  smokey.run
end

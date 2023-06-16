desc "run Smoke tests"

task smoke: :environment do
  require File.join(Rails.root, "lib", "smoketest")

  smokey = Smoketest.new
  smokey.run
end

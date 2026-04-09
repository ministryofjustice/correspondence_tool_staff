require "rails_helper"
require "rake"

RSpec.describe "reports:refresh_cache rake task" do
  before do
    Rake.application.rake_require("tasks/reports_cache")
    Rake::Task.define_task(:environment)
    task.reenable
  end

  let(:task_name) { "reports:refresh_cache" }
  let(:task) { Rake::Task[task_name] }

  it "invokes the Reports::CacheRefresher service" do
    allow(Reports::CacheRefresher).to receive(:call).and_return({ successes: 1, failures: 0, duration_ms: 10.0 })
    expect { task.invoke }.to output(/reports:refresh_cache/).to_stdout
  end
end

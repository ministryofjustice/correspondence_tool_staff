require "rails_helper"
require "rake"

RSpec.describe "bank_holidays rake tasks" do
  let(:task_name) { "bank_holidays:run" }

  def load_rake_task
    Rake::Task.clear
    Rake.application = Rake::Application.new
    # Define a no-op environment task to satisfy task prerequisites in test env
    Rake::Task.define_task(:environment)
    load Rails.root.join("lib/tasks/bank_holidays.rake")
  end

  before do
    load_rake_task
  end

  it "defines the bank_holidays:run task" do
    expect { Rake::Task[task_name] }.not_to raise_error
  end

  it "invokes BankHolidaysService when the task runs" do
    expect(BankHolidaysService).to receive(:new)
    Rake::Task[task_name].invoke
  end

  it "can be re-invoked when reenabled" do
    expect(BankHolidaysService).to receive(:new).twice

    task = Rake::Task[task_name]
    task.invoke
    task.reenable
    task.invoke
  end
end

require "rails_helper"
require "rake"

RSpec.describe "data_request_areas rake tasks" do
  def load_rake_task
    Rake::Task.clear
    Rake.application = Rake::Application.new
    # Define a no-op environment task to satisfy task prerequisites in test env
    Rake::Task.define_task(:environment)
    load Rails.root.join("lib/tasks/data_request_areas.rake")
  end

  before do
    load_rake_task
  end

  let(:contact) { create(:contact, name: "HMP Leeds") }
  let(:data_request_area) { create(:data_request_area, contact:) }

  describe "data_request_areas:backfill_blank_locations" do
    let(:task_name) { "data_request_areas:backfill_blank_locations" }

    it "defines the task" do
      expect { Rake::Task[task_name] }.not_to raise_error
    end

    it "fills a nil location from the linked contact" do
      data_request_area.update_column(:location, nil)

      expect { Rake::Task[task_name].invoke }.to output(/Updated 1 data request area/).to_stdout
      expect(data_request_area.reload.location).to eq "HMP Leeds"
    end

    it "fills an empty string location from the linked contact" do
      data_request_area.update_column(:location, "")

      Rake::Task[task_name].invoke
      expect(data_request_area.reload.location).to eq "HMP Leeds"
    end

    it "does not overwrite an existing location" do
      data_request_area.update_column(:location, "Existing value")

      expect { Rake::Task[task_name].invoke }.to output(/Updated 0 data request area/).to_stdout
      expect(data_request_area.reload.location).to eq "Existing value"
    end

    it "leaves records without a contact untouched" do
      no_contact = create(:data_request_area, contact: nil, location: "Free text")

      Rake::Task[task_name].invoke
      expect(no_contact.reload.location).to eq "Free text"
    end

    it "fills a blank data request location from its data request area" do
      data_request = create(:data_request, data_request_area:)
      data_request.update_column(:location, nil)

      Rake::Task[task_name].invoke
      expect(data_request.reload.location).to eq "HMP Leeds"
    end

    it "does not overwrite an existing data request location" do
      data_request = create(:data_request, data_request_area:)
      data_request.update_column(:location, "Legacy value")

      Rake::Task[task_name].invoke
      expect(data_request.reload.location).to eq "Legacy value"
    end

    it "fills both tables when both locations are blank" do
      data_request = create(:data_request, data_request_area:)
      data_request_area.update_column(:location, nil)
      data_request.update_column(:location, "")

      Rake::Task[task_name].invoke
      expect(data_request_area.reload.location).to eq "HMP Leeds"
      expect(data_request.reload.location).to eq "HMP Leeds"
    end
  end

  describe "data_request_areas:force_sync_locations" do
    let(:task_name) { "data_request_areas:force_sync_locations" }

    it "defines the task" do
      expect { Rake::Task[task_name] }.not_to raise_error
    end

    it "overwrites a stale location with the contact name" do
      data_request_area.update_column(:location, "Stale value")

      expect { Rake::Task[task_name].invoke }.to output(/Updated 1 data request area/).to_stdout
      expect(data_request_area.reload.location).to eq "HMP Leeds"
    end

    it "fills a nil location from the linked contact" do
      data_request_area.update_column(:location, nil)

      Rake::Task[task_name].invoke
      expect(data_request_area.reload.location).to eq "HMP Leeds"
    end

    it "leaves records without a contact untouched" do
      no_contact = create(:data_request_area, contact: nil, location: "Free text")

      Rake::Task[task_name].invoke
      expect(no_contact.reload.location).to eq "Free text"
    end

    it "overwrites a stale data request location from the data request area" do
      data_request = create(:data_request, data_request_area:)
      data_request.update_column(:location, "Stale value")

      Rake::Task[task_name].invoke
      expect(data_request.reload.location).to eq "HMP Leeds"
    end

    it "syncs data requests under contact-less areas with a free-text location" do
      no_contact = create(:data_request_area, contact: nil, location: "Free text")
      data_request = create(:data_request, data_request_area: no_contact)
      data_request.update_column(:location, "Stale value")

      Rake::Task[task_name].invoke
      expect(data_request.reload.location).to eq "Free text"
    end
  end

  describe "data_request_areas:location_drift_report" do
    let(:task_name) { "data_request_areas:location_drift_report" }

    it "defines the task" do
      expect { Rake::Task[task_name] }.not_to raise_error
    end

    it "reports zero drift when locations are in sync" do
      create(:data_request, data_request_area:)

      expect { Rake::Task[task_name].invoke }
        .to output(/0 data request area\(s\).*\n0 data request\(s\)/).to_stdout
    end

    it "reports drifted areas and data requests and suggests reconciliation" do
      data_request = create(:data_request, data_request_area:)
      data_request_area.update_column(:location, "Drifted")
      data_request.update_column(:location, "Also drifted")

      expect { Rake::Task[task_name].invoke }
        .to output(/1 data request area\(s\).*\n1 data request\(s\).*\n.*force_sync_locations/).to_stdout
    end
  end
end

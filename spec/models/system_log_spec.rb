# == Schema Information
#
# Table name: system_logs
#
#  id            :bigint           not null, primary key
#  type          :string           not null
#  status        :string           default("pending")
#  reference_id  :string
#  action        :string
#  source        :string
#  metadata      :jsonb            default({})
#  error_message :text
#  duration_ms   :float
#  completed_at  :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require "rails_helper"

RSpec.describe SystemLog, type: :model do
  describe "factory" do
    it "produces a valid object by default" do
      system_log = build(:system_log)
      expect(system_log).to be_valid
    end

    it "produces a valid successful log" do
      system_log = build(:system_log, :successful)
      expect(system_log).to be_valid
      expect(system_log.status).to eq "success"
      expect(system_log.completed_at).to be_present
    end

    it "produces a valid failed log" do
      system_log = build(:system_log, :failed)
      expect(system_log).to be_valid
      expect(system_log.status).to eq "failed"
      expect(system_log.error_message).to be_present
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:type) }
  end

  describe "scopes" do
    let!(:pending_log) { create(:system_log, status: "pending") }
    let!(:successful_log) { create(:system_log, :successful) }
    let!(:failed_log) { create(:system_log, :failed) }
    let!(:old_log) { create(:system_log, created_at: 1.year.ago) }

    describe ".recent" do
      it "returns logs ordered by created_at desc" do
        logs = described_class.recent
        expect(logs.first).to eq failed_log
      end

      it "limits to 500 records" do
        expect(described_class.recent.limit_value).to eq 500
      end
    end

    describe ".pending" do
      it "returns only pending logs" do
        expect(described_class.pending).to contain_exactly(pending_log, old_log)
      end
    end

    describe ".successful" do
      it "returns only successful logs" do
        expect(described_class.successful).to contain_exactly(successful_log)
      end
    end

    describe ".failed" do
      it "returns only failed logs" do
        expect(described_class.failed).to contain_exactly(failed_log)
      end
    end
  end

  describe "#complete!" do
    let(:log) { create(:system_log, status: "pending") }

    it "updates status to success" do
      log.complete!
      expect(log.reload.status).to eq "success"
    end

    it "sets completed_at timestamp" do
      freeze_time do
        log.complete!
        expect(log.reload.completed_at).to eq Time.current
      end
    end

    it "sets duration_ms when provided" do
      log.complete!(duration: 150.5)
      expect(log.reload.duration_ms).to eq 150.5
    end
  end

  describe "#fail!" do
    let(:log) { create(:system_log, status: "pending") }

    it "updates status to failed" do
      log.fail!("Error occurred")
      expect(log.reload.status).to eq "failed"
    end

    it "sets error_message" do
      log.fail!("Something went wrong")
      expect(log.reload.error_message).to eq "Something went wrong"
    end

    it "sets duration_ms when provided" do
      log.fail!("Error", duration: 75.0)
      expect(log.reload.duration_ms).to eq 75.0
    end
  end
end

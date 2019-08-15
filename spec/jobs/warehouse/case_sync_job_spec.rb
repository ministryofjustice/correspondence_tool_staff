require 'rails_helper'

describe Warehouse::CaseSyncJob, type: :job do
  include ActiveJob::TestHelper

  before(:each) do
    ActiveJob::Base.queue_adapter = :test
    allow(RavenContextProvider).to receive(:set_context)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  describe '#perform' do
    let(:job) { described_class.new }
    let(:user) { find_or_create :default_press_officer }

    it 'is in the warehouse queue' do
      expect(job.queue_name).to eq('correspondence_tool_staff_warehouse')
    end

    it 'requires ActiveModel class type string' do
      model_id = -rand(1..998)

      expect { job.perform(Object.new, model_id) }.to raise_error
      expect { job.perform(User, model_id) }.to raise_error
      expect { job.perform(User.new, model_id) }.to raise_error
      expect(job.perform('User', model_id)).to be true
    end

    it 'logs to Rails logger if ActiveRecord model retrieval fails' do
      expect(Rails.logger).to receive(:error).with(/FAIL/)
      job.perform('User', -987654321)
    end

    it 'performs later' do
      perform_enqueued_jobs do
        expect_any_instance_of(described_class).to receive(:perform).with(user.class.to_s, user.id)
        described_class.perform_later(user.class.to_s, user.id)
      end
    end

    it 'syncs the ActiveRecord' do
      allow(::Stats::Warehouse::CaseReportSync).to receive(:new).with(user)
      job.perform(user.class.to_s, user.id)
    end
  end
end

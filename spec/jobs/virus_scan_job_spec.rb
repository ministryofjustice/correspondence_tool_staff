require "rails_helper"

describe VirusScanJob, type: :job do
  include ActiveJob::TestHelper

  let(:attachment) { instance_double CaseAttachment }

  before(:each) do
    ActiveJob::Base.queue_adapter = :test
    allow(RavenContextProvider).to receive(:set_context)
    allow(CaseAttachment).to       receive(:find)
                                     .with(123)
                                     .and_return(attachment)
    allow(attachment).to           receive(:scan_for_virus)
  end

  describe '.perform' do
    it 'queues the job' do
      expect { described_class.perform_later(123) }.to have_enqueued_job(described_class)
    end

    it 'sets the Raven environment' do
      described_class.perform_now(123)
      expect(RavenContextProvider).to have_received(:set_context)
    end

    it 'runs scan_for_virus on case attachment object' do
      described_class.perform_now(123)
      expect(attachment).to have_received(:scan_for_virus)
    end
  end
end

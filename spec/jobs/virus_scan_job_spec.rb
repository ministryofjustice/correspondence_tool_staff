require "rails_helper"

describe PdfMakerJob, type: :job do
  include ActiveJob::TestHelper

  before(:each) do
    ActiveJob::Base.queue_adapter = :test
    allow(RavenContextProvider).to receive(:set_context)
    # @attachment = double CaseAttachment
    # allow(CaseAttachment).to receive(:find).with(123).and_return(@attachment)
    # allow(@attachment).to receive(:make_preview)
  end

  describe '.perform' do
    it 'sets the Raven environment' do
      described_class.perform_now(123)
      expect(RavenContextProvider).to have_received(:set_context)
    end

    it 'queues the job' do
      expect { described_class.perform_later(123) }.to have_enqueued_job(described_class)
    end

    it 'runs scan_for_virus on case attachment object'

    # after do
    #   clear_enqueued_jobs
    #   clear_performed_jobs
    # end
  end
end

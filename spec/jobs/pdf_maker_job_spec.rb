require 'rails_helper'

describe PdfMakerJob, type: :job do
  include ActiveJob::TestHelper

  before(:each) do
    ActiveJob::Base.queue_adapter = :test
    @attachment = double CaseAttachment
    allow(CaseAttachment).to receive(:find).with(123).and_return(@attachment)
    allow(@attachment).to receive(:make_preview)
  end

  describe '.perform' do

    it 'queues the job' do
      expect { described_class.perform_later(123) }.to have_enqueued_job(described_class)
    end

    it 'is in default queue' do
      expect(described_class.new.queue_name).to eq('correspondence_tool_staff_pdf_maker')
    end

    it 'executes perform' do
      attachment_1 = double CaseAttachment
      expect(CaseAttachment).to receive(:find).with(123).and_return(attachment_1)
      expect(attachment_1).to receive(:make_preview)
      perform_enqueued_jobs { described_class.perform_later(123) }
    end

    it 'handles no ActiveRecord::RecordNotFound error' do
      allow(CaseAttachment).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      errmsg = 'PdfMakerJob Error creating Preview for attachment 123: ActiveRecord::RecordNotFound - ActiveRecord::RecordNotFound'
      expect(Rails.logger).to receive(:error).with(errmsg)

      described_class.perform_now(123)
    end

    context 'excepition' do
      it 'logs the error and sets the preview_key to nil' do
        expect(@attachment).to receive(:make_preview).and_raise(RuntimeError, 'Some specific error')
        expect(Rails.logger).to receive(:error).with("PdfMakerJob Error creating Preview for attachment 123: RuntimeError - Some specific error")
        expect(@attachment).to receive(:preview_key=).with(nil)
        described_class.perform_now(123)
      end

    end
  end


  describe '.perform_with_delay' do

    before(:each) do
      described_class.perform_with_delay(8766, 2)
    end

    let(:jobs) { queue_adapter.enqueued_jobs }
    let(:job) { jobs.first }

    it 'queues a job of the right class' do
      expect(job[:job]).to eq PdfMakerJob
    end

    it 'queues a job with the specified arguments' do
      expect(job[:args]).to eq [8766, 2]
    end

    it 'queues the job on the correct queue' do
      expect(job[:queue]).to eq 'correspondence_tool_staff_pdf_maker'
    end

    it 'queues it for execution between 4 and 5 minutes from now' do
      execution_time = Time.at(job[:at])
      expect(time_between(execution_time, 4.minutes.from_now, 5.minutes.from_now)).to be true
    end

    def time_between(time_to_test, lower_limit, upper_limit)
      time_to_test > lower_limit && time_to_test < upper_limit
    end
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end

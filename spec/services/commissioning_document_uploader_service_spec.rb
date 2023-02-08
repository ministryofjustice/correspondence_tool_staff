require 'rails_helper'

describe CommissioningDocumentUploaderService do
  let(:upload_group) { '20170615102233' }
  let(:responder) { find_or_create :foi_responder }
  let(:kase) { create(:accepted_case, responder: responder) }
  let(:commissioning_document) { create(:commissioning_document) }
  let(:user) { kase.responder }
  let(:filename) { "#{Faker::Internet.slug}.jpg" }
  let(:uploads_key) { "uploads/#{kase.id}/requests/#{filename}" }
  let(:uploaded_file) { uploads_key }
  let(:service) do
    CommissioningDocumentUploaderService.new(
      kase: kase,
      commissioning_document: commissioning_document,
      current_user: user,
      uploaded_file: uploaded_file
    )
  end
  let(:attachments) { [create(:commissioning_document_attachment)] }
  let(:uploader) { instance_double(S3Uploader, process_files: attachments) }

  before(:each) do
    ActiveJob::Base.queue_adapter = :test
    allow(S3Uploader).to receive(:new).and_return(uploader)
  end

  after(:all) { DbHousekeeping.clean(seed: true) }

  describe '#upload!' do
    context 'action upload' do
      it 'calls #process_files on the uploader' do
        service.upload!
        expect(uploader).to have_received(:process_files)
                              .with(uploads_key, :commissioning_document)
      end

      it 'returns the attachments created' do
        expect(service.upload!).to eq attachments.first
      end

      it 'gives a result of :ok' do
        service.upload!
        expect(service.result).to eq :ok
      end

      it 'associated the attachment to the commissioning document' do
        expect {
          service.upload!
        }.to change {
          commissioning_document.attachment_id
        }
      end

      context 'No valid files to upload' do
        let(:uploaded_file) { [] }

        it 'returns a result of :blank' do
          service.upload!
          expect(service.result).to eq :blank
        end
      end

      describe 'uploader raises an S3 service error' do
        before do
          allow(uploader)
            .to receive(:process_files)
                  .with(uploads_key, :commissioning_document)
                  .and_raise(Aws::S3::Errors::ServiceError.new(:foo, :bar))
        end

        it 'returns :error' do
          service.upload!
          expect(service.result).to eq :error
        end
      end

      describe 'uploader raises a record invalid error' do
        before do
          allow(uploader)
            .to receive(:process_files)
                  .with(uploads_key, :commissioning_document)
                  .and_raise(ActiveRecord::RecordInvalid)
        end

        it 'returns :error' do
          service.upload!
          expect(service.result).to eq :error
        end
      end

      describe 'uploader raises an record not unique' do
        before do
          allow(uploader)
            .to receive(:process_files)
                  .with(uploads_key, :commissioning_document)
                  .and_raise(ActiveRecord::RecordNotUnique)
        end

        it 'returns :error' do
          service.upload!
          expect(service.result).to eq :error
        end
      end

      describe 'uploader raises an S3 service error' do
        before do
          allow(uploader)
            .to receive(:process_files)
                  .with(uploads_key, :commissioning_document)
                  .and_raise(Aws::S3::Errors::ServiceError.new(:foo, :bar))
        end

        it 'returns :error' do
          service.upload!
          expect(service.result).to eq :error
        end
      end
    end
  end

end

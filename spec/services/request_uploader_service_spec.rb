require 'rails_helper'

describe RequestUploaderService do

  let(:upload_group)       {  Time.new(2017, 6, 15, 10, 22, 33).strftime('%Y%m%d%H%M%S') }
  let(:responder)          { find_or_create :foi_responder }
  let(:kase)               { create(:accepted_case, responder: responder) }
  let(:user)               { kase.responder }
  let(:filename)           { "#{Faker::Internet.slug}.jpg" }
  let(:uploads_key)        { "uploads/#{kase.id}/requests/#{filename}" }
  let(:uploaded_files)     { [uploads_key] }
  let(:upload_comment)     { nil }
  let(:rus)                { RequestUploaderService.new(
                               kase: kase,
                               current_user: user,
                               uploaded_files: uploaded_files,
                               upload_comment: upload_comment,
                             ) }
  let(:rus_with_message)   { RequestUploaderService.new(
                               kase: kase,
                               current_user: user,
                               uploaded_files: [uploads_key],
                               upload_comment: 'This is my upload message',
                             ) }
  let(:attachments)        { [instance_double(CaseAttachment,
                                              filename: filename)] }
  let(:uploader)           { instance_double(S3Uploader,
                                             process_files: attachments) }

  before(:each) do
    ActiveJob::Base.queue_adapter = :test
    allow(S3Uploader).to receive(:new).and_return(uploader)
  end
  
  after(:all) { DbHousekeeping.clean(seed: true) }

  describe '#upload!' do
    context 'action upload' do

      let(:action) { 'upload' }

      it 'calls #process_files on the uploader' do
        rus.upload!
        expect(uploader).to have_received(:process_files)
                              .with([uploads_key], :request)
      end

      it 'returns the attachments created' do
        expect(rus.upload!).to eq attachments
      end

      it 'gives a result of :ok' do
        rus.upload!
        expect(rus.result).to eq :ok
      end

      it 'creates a transition with a message' do
        rus_with_message.upload!
        transition = kase.transitions.last
        expect(transition.event).to eq 'add_message_to_case'
        expect(transition.metadata).to eq({ 'filenames' => [filename], 'message' => "This is my upload message" })
      end

      context 'No valid files to upload' do
        let(:uploaded_files) { [] }
        it 'returns a result of :blank' do
          rus.upload!
          expect(rus.result).to eq :blank

        end
      end

      describe 'uploader raises an S3 service error' do
        before do
          allow(uploader)
            .to receive(:process_files)
                  .with([uploads_key], :request)
                  .and_raise(Aws::S3::Errors::ServiceError.new(:foo, :bar))
        end

        it 'returns :error' do
          rus.upload!
          expect(rus.result).to eq :error
        end
      end

      describe 'uploader raises a record invalid error' do
        before do
          allow(uploader)
            .to receive(:process_files)
                  .with([uploads_key], :request)
                  .and_raise(ActiveRecord::RecordInvalid)
        end

        it 'returns :error' do
          rus.upload!
          expect(rus.result).to eq :error
        end
      end

      describe 'uploader raises an record not unique' do
        before do
          allow(uploader)
            .to receive(:process_files)
                  .with([uploads_key], :request)
                  .and_raise(ActiveRecord::RecordNotUnique)
        end

        it 'returns :error' do
          rus.upload!
          expect(rus.result).to eq :error
        end
      end

      describe 'uploader raises an S3 service error' do
        before do
          allow(uploader)
            .to receive(:process_files)
                  .with([uploads_key], :request)
                  .and_raise(Aws::S3::Errors::ServiceError.new(:foo, :bar))
        end

        it 'returns :error' do
          rus.upload!
          expect(rus.result).to eq :error
        end
      end
    end
  end

end

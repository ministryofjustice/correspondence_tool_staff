require 'rails_helper'

describe S3Uploader do
  let!(:time)              { Time.new(2017, 6, 15, 10, 22, 33) }
  let(:upload_group)       { '20170615102233' }
  let(:responder)          { find_or_create :foi_responder }
  let(:kase)               { create(:accepted_case, responder: responder) }
  let(:filename)           { "#{Faker::Internet.slug}.jpg" }
  let(:uploads_key)        { "uploads/#{kase.id}/responses/#{filename}" }
  let(:destination_key)    { "#{kase.id}/responses/#{upload_group}/#{filename}" }
  let(:destination_path)   { "correspondence-staff-case-uploads-testing/#{destination_key}" }
  let(:uploads_object)     { instance_double(Aws::S3::Object, 'uploads_object') }
  let(:public_url)         { URI.join(CASE_UPLOADS_S3_BUCKET.url, destination_key) }
  let(:destination_object) { instance_double Aws::S3::Object, 'destination_object', public_url: public_url }
  let(:leftover_files)     { [] }
  let(:state_machine)      { double CaseStateMachine }
  let(:uploader)           { S3Uploader.new(kase, responder) }
  let(:uploaded_files)     { [uploads_key] }
  let(:attachment_type)    { :response }

  before(:each) do

    allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                       .with(uploads_key)
                                       .and_return(uploads_object)
    allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                       .with(destination_key)
                                       .and_return(destination_object)
    allow(CASE_UPLOADS_S3_BUCKET).to receive(:objects)
                                       .with(prefix: "uploads/#{kase.id}")
                                       .and_return(leftover_files)
    allow(uploads_object).to receive(:move_to).with(destination_path)
  end

  describe '.s3_direct_post_for_case' do
    it 'retrieves an s3 presigned post' do
      allow(CASE_UPLOADS_S3_BUCKET).to receive(:presigned_post)
                                         .and_return(:a_presigned_post)
      kase = instance_spy(Case::Base, uploads_dir: ':id/:type')
      result = S3Uploader.s3_direct_post_for_case(kase, ':type')
      expect(result).to eq :a_presigned_post
      expect(kase).to have_received(:uploads_dir).with(':type')
      expect(CASE_UPLOADS_S3_BUCKET)
        .to have_received(:presigned_post)
              .with(key: 'uploads/:id/:type/${filename}',
                    success_action_status: '201')
    end
  end

  describe '.id_for_case' do
    it 'returns the case id if persisted' do
      kase = instance_double(Case::Base, persisted?: true, id: :case_id)
      expect(S3Uploader.id_for_case(kase)).to eq :case_id
    end

    it 'returns a random string if case not persisted' do
      kase = instance_double(Case::Base, persisted?: false, id: :case_id)
      allow(SecureRandom).to receive(:urlsafe_base64)
                               .and_return('ran-dom string')
      expect(S3Uploader.id_for_case(kase)).to eq 'ran-dom string'
    end
  end

  describe '#process_files' do

    before(:each) { ActiveJob::Base.queue_adapter = :test }

    it 'creates a new case attachment' do
      Timecop.freeze(time) do
        expect{ uploader.process_files(uploaded_files, :response) }
        .to change { kase.reload.attachments.count }.by(1)
      end
    end

    it 'moves uploaded object to destination path' do
      Timecop.freeze(time) do
        uploader.process_files(uploaded_files, :response)
        expect(uploads_object).to have_received(:move_to).with(destination_path)
      end
    end

    context 'response files' do
      it 'makes the attachment type a response' do
        Timecop.freeze(time) do
          uploader.process_files(uploaded_files, :response)
          expect(kase.attachments.first.type).to eq 'response'
        end
      end
    end

    context 'request files' do
      it 'makes the attachment type a request' do

        request_uploads_key = "uploads/#{kase.id}/requests/#{filename}"
        request_destination_key =
          "#{kase.id}/requests/#{upload_group}/#{filename}"
        request_destination_path =
          "correspondence-staff-case-uploads-testing/#{request_destination_key}"

        allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                           .with(request_uploads_key)
                                           .and_return(uploads_object)
        allow(uploads_object).to receive(:move_to)
                                   .with(request_destination_path)
        Timecop.freeze(time) do
          uploader.process_files([request_uploads_key], :request)
          expect(kase.attachments.first.type).to eq 'request'
        end
      end
    end

    describe 'pdf job queueing' do
      it 'queues a job for each file that is not a commissioning_document' do
        Timecop.freeze(time) do
          attachments = [
            create(:correspondence_response, case_id: kase.id),
            create(:commissioning_document_attachment, case_id: kase.id),
            create(:correspondence_response, case_id: kase.id)
          ]
          uploader.process_files(uploaded_files, :response)
          allow(uploader).to receive(:create_attachments)
                               .and_return(attachments)

          expect(PdfMakerJob).to receive(:perform_later)
                                   .with(attachments[0].id)
          expect(PdfMakerJob).to_not receive(:perform_later)
                                   .with(attachments[1].id)
          expect(PdfMakerJob).to receive(:perform_later)
                                   .with(attachments[2].id)
          uploader.process_files(uploaded_files, :response)
        end
      end
    end

    context 'files removed from dropzone upload' do
      let(:leftover_files) do
        [instance_double(Aws::S3::Object, delete: nil)]
      end

      it 'removes any files left behind in uploads' do
        Timecop.freeze(time) do
          uploader.process_files(uploaded_files, :response)
          leftover_files.each do |object|
            expect(object).to have_received(:delete)
          end
        end
      end
    end

    context 'error when creating case attachment' do
      before do
        allow(CaseAttachment).to receive(:create!)
                                   .and_raise(ActiveRecord::RecordNotUnique)
      end

      it 'passes exception through to the caller' do
        Timecop.freeze(time) do
          expect { uploader.process_files(uploaded_files, :response) }
            .to raise_error(ActiveRecord::RecordNotUnique)
        end
      end

      it 'does not create a new case_attachment object' do
        Timecop.freeze(time) do
          expect {
            uploader.process_files(uploaded_files, :response) rescue nil
          }.not_to change{ CaseAttachment.count }
        end
      end
    end

    context 'error when moving file in S3' do
      before do
        allow(uploads_object).to receive(:move_to)
                                   .with(destination_path)
                                   .and_raise(
                                     Aws::S3::Errors::ServiceError.new(:foo, :bar)
                                   )
      end

      it 'passes exception through to the caller' do
        Timecop.freeze(time) do
          expect { uploader.process_files(uploaded_files, :response) }
            .to raise_error(Aws::S3::Errors::ServiceError)
        end
      end

      it 'does not create a new case_attachment object' do
        Timecop.freeze(time) do
          expect {
            uploader.process_files(uploaded_files, :response) rescue nil
          }.not_to change{ CaseAttachment.count }
        end
      end
    end
  end
end


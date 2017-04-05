require 'rails_helper'

describe ResponseUploaderService do

  let(:responder) { create :responder }
  let(:kase) { create(:accepted_case, responder: responder) }
  let(:uploads_key) do
    "uploads/#{kase.id}/responses/#{Faker::Internet.slug}.jpg"
  end
  let(:destination_key) { uploads_key.sub(%r{^uploads/}, '') }
  let(:destination_path) do
    "correspondence-staff-case-uploads-testing/#{destination_key}"
  end
  let(:uploads_object) { instance_double(Aws::S3::Object, 'uploads_object') }
  let(:public_url) do
    "#{CASE_UPLOADS_S3_BUCKET.url}/#{URI.encode(destination_key)}"
  end
  let(:destination_object) do
    instance_double Aws::S3::Object, 'destination_object',
                    public_url: public_url
  end
  let(:leftover_files) { [] }

  before do
    allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                       .with(uploads_key)
                                       .and_return(uploads_object)
    allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                       .with(destination_key)
                                       .and_return(destination_object)
    allow(CASE_UPLOADS_S3_BUCKET).to receive(:objects)
                                       .with(prefix: "uploads/#{kase.id}")
                                       .and_return(leftover_files)
    allow(uploads_object).to receive(:move_to).with(
                               destination_path
                             )
  end


  describe '#upload!' do

    before(:each) { ActiveJob::Base.queue_adapter = :test }

    let(:params) do
      ActionController::Parameters.new(
        {
          "type"=>"response",
          "uploaded_files"=>[uploads_key],
          "id"=>kase.id.to_s,
          "controller"=>"cases",
          "action"=>"upload_responses"}
      )
    end

    let(:rus) { ResponseUploaderService.new(kase, kase.responder, params) }

    it 'creates a new case attachment' do
      expect{ rus.upload! }.to change { kase.reload.attachments.count }.by(1)
    end

    it 'moves uploaded object to destination path' do
      rus.upload!
      expect(uploads_object).to have_received(:move_to).with(destination_path)
    end

    it 'makes the attachment type a response' do
      rus.upload!
      expect(kase.attachments.first.type).to eq 'response'
    end

    it 'gives a result of :ok' do
      rus.upload!
      expect(rus.result).to eq :ok
    end

    context 'pdf job queueing' do

      it 'queues a job for each file' do
        response_attachments = [
          create(:correspondence_response, case_id: kase.id),
          create(:correspondence_response, case_id: kase.id)
        ]
        allow(rus).to receive(:response_attachments).and_return(response_attachments)
        expect(PdfMakerJob).to receive(:perform_later).with(response_attachments.first.id)
        expect(PdfMakerJob).to receive(:perform_later).with(response_attachments.last.id)
        rus.upload!
      end
    end

    context 'files removed from dropzone upload' do
      let(:leftover_files) do
        [instance_double(Aws::S3::Object, delete: nil)]
      end

      it 'removes any files left behind in uploads' do
        rus.upload!
        leftover_files.each do |object|
          expect(object).to have_received(:delete)
        end
      end
    end
    context 'an attachment already exists with the same name' do
      let(:attachment) do
        create :case_response,
               key: destination_key,
               case: kase
      end

      before do
        attachment
      end

      it 'does not create a new case_attachment object' do
        expect { rus.upload! }.not_to change { kase.reload.attachments.count }
      end

      it 'updates the updated_at time of the existing attachment' do
        expect { rus.upload! }.to change { kase.reload.attachments.first.updated_at }
      end

      it 'updates the existing attachment' do
        rus.upload!
        expect(uploads_object).to have_received(:move_to).with(destination_path)
      end
    end

    context 'uploading invalid attachment type' do
      let(:uploads_key) do
        "uploads/#{kase.id}/responses/invalid.exe"
      end

      it 'renders the new_response_upload page' do
        rus.upload!
        expect(rus.result).to eq :error
      end

      it 'does not create a new case attachment' do
        expect { rus.upload! }.to_not change { kase.reload.attachments.count }
      end

      xit 'removes the attachment from S3'
    end

    context 'uploading attachment that are too large' do
      xit 'renders the new_response_upload page' do
        rus.upload!
        expect(rus.result).to eq :error
      end

      xit 'does not create a new case attachment' do
        expect { do_upload_responses }.to_not change { kase.reload.attachments.count }
      end

      xit 'removes the attachment from S3'
    end

    context 'No valid files to upload' do
      it 'returns a result of :blank' do
        params.delete('uploaded_files')
        rus.upload!
        expect(rus.result).to eq :blank
      end
    end

  end
end


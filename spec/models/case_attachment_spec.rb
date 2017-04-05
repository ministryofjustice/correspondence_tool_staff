# == Schema Information
#
# Table name: case_attachments
#
#  id          :integer          not null, primary key
#  case_id     :integer
#  type        :enum
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  key         :string
#  preview_key :string
#

require 'rails_helper'
require 'rspec/expectations'

RSpec::Matchers.define :allow_file_extension do |extension|
  match do
    subject.key = "uploads/file.#{extension}"
    subject.type = 'response'
    subject.valid?
  end
end

RSpec.describe CaseAttachment, type: :model do
  describe 'type enum' do
    it { should have_enum(:type).with_values ['response'] }
    it { should validate_presence_of :type }
  end

  describe 'key' do
    describe 'file extension validation' do
      it { should allow_file_extension('pdf')  }
      it { should allow_file_extension('doc')  }
      it { should allow_file_extension('docx') }
      it { should allow_file_extension('xls')  }
      it { should allow_file_extension('xlsx') }

      it { should_not allow_file_extension('exe') }
      it { should_not allow_file_extension('com') }
      it { should_not allow_file_extension('bat') }
    end

    it { should validate_presence_of :key }
  end

  describe '#filename' do
    subject do
      create :case_attachment,
             type: 'response',
             key: "#{SecureRandom.hex(16)}/responses/new response.pdf"
    end

    it 'returns the name of the attached file' do
      expect(subject.filename).to eq 'new response.pdf'
    end
  end

  context 'time-limited URLs' do
    subject do
      create :case_attachment,
             type: 'response',
             key: "4/responses/new response.docx",
             preview_key: "4/response_previews/new response.pdf"

    end

    let(:object)        { instance_double(Aws::S3::Object) }
    let(:presigned_url) { instance_double(String, "presigned_url") }

    describe '#temporary_url' do
      before do
        allow(CASE_UPLOADS_S3_BUCKET).to receive(:object).with(subject.key)
                                           .and_return(object)
        allow(object).to receive(:presigned_url)
                           .with(:get, expires_in: 900)
                           .and_return(presigned_url)
      end

      it 'creates a pre-signed url that is good for 15 mins' do
        expect(subject.temporary_url).to be presigned_url
      end
    end

    describe '#temporary_preview_url' do
      before do
        allow(CASE_UPLOADS_S3_BUCKET).to receive(:object).with(subject.preview_key)
                                           .and_return(object)
        allow(object).to receive(:presigned_url)
                           .with(:get, expires_in: 900)
                           .and_return(presigned_url)
      end

      context 'preview_key exists' do
        it 'creates a pre-signed url that is good for 15 mins' do
          expect(subject.temporary_preview_url).to be presigned_url
        end
      end

      context 'preview key is nil' do
        it 'returns nil' do
          subject.preview_key = nil
          expect(subject.temporary_preview_url).to be_nil
        end
      end

    end
  end


  it 'removes the file from the storage bucket on destruction' do
    attachment = create :case_response
    attachment_object = instance_double(
      Aws::S3::Object,
      delete: instance_double(Aws::S3::Types::DeleteObjectOutput)
    )
    allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                       .with(attachment.key)
                                       .and_return(attachment_object)

    attachment.destroy!

    expect(attachment_object).to have_received(:delete)
  end

  describe '#make_preview' do

    let(:pdf_case_attachment) { create :correspondence_response, :without_preview_key }
    let(:jpg_case_attachment) { create :correspondence_response, key: '6/responses/my_photo.jpg' }

    context 'original file is pdf' do
      it 'copies key to preview key' do
        expect(pdf_case_attachment.preview_key).to be_nil
        pdf_case_attachment.make_preview(0)
        expect(pdf_case_attachment.preview_key).to eq pdf_case_attachment.key
      end

      it 'does not call Libreconv' do
        expect(Libreconv).not_to receive(:convert)
        pdf_case_attachment.make_preview(0)
      end
    end

    context 'original file is not pdf' do

      it 'calls Libreconv.covert and uploads file' do
        expect(jpg_case_attachment).to receive(:download_original_file).and_return('tempfile_orig.jpg')
        expect(jpg_case_attachment).to receive(:make_preview_filename).and_return('tempfile_preview.pdf')
        expect(Libreconv).to receive(:convert).with('tempfile_orig.jpg', 'tempfile_preview.pdf')
        expect(jpg_case_attachment).to receive(:upload_preview)

        jpg_case_attachment.make_preview(0)
      end

      it 'updates the preview_key' do
        allow(jpg_case_attachment).to receive(:download_original_file).and_return('tempfile_orig.jpg')
        allow(jpg_case_attachment).to receive(:make_preview_filename).and_return('tempfile_preview.pdf')
        allow(Libreconv).to receive(:convert).with('tempfile_orig.jpg', 'tempfile_preview.pdf')
        allow(jpg_case_attachment).to receive(:upload_preview).and_return('/6/response_previews/tempfile_preview.pdf')

        jpg_case_attachment.make_preview(0)

        expect(jpg_case_attachment.reload.preview_key).to eq '/6/response_previews/tempfile_preview.pdf'
      end
    end

    context 'exception raised during conversion process' do
      it 'sets the preview_key to nil' do
        expect(jpg_case_attachment).to receive(:download_original_file).and_return('tempfile_orig.jpg')
        expect(jpg_case_attachment).to receive(:make_preview_filename).and_return('tempfile_preview.pdf')
        expect(Libreconv).to receive(:convert).with('tempfile_orig.jpg', 'tempfile_preview.pdf').and_raise(RuntimeError)
        expect(jpg_case_attachment).not_to receive(:upload_preview)

        jpg_case_attachment.make_preview(0)
        expect(jpg_case_attachment.reload.preview_key).to be_nil
      end
    end

    context 'private methods' do

      describe 'private method dowload_original_file' do
        it 'downloads file and puts in a temporary file' do
          tempfile = double Tempfile, close: nil, path: '/tmp/xxx_my_photo.jpg'
          expect(Tempfile).to receive(:new).with(['orig', '.jpg']).and_return(tempfile)
          s3_object = double 'S3 Object'
          expect(CASE_UPLOADS_S3_BUCKET).to receive(:object).with('6/responses/my_photo.jpg').and_return(s3_object)
          expect(s3_object).to receive(:get).with(response_target: '/tmp/xxx_my_photo.jpg')

          download_file_path = jpg_case_attachment.__send__(:download_original_file)
          expect(download_file_path).to eq '/tmp/xxx_my_photo.jpg'
        end
      end

      describe 'private method make_preview_filename' do
        it 'returns the preview filename based on the key' do
          tempfile = double Tempfile, close: nil, path: '/tmp/xxx_my_photo.pdf'
          expect(Tempfile).to receive(:new).with(['preview', '.pdf']).and_return(tempfile)
          preview_path = jpg_case_attachment.__send__(:make_preview_filename)
          expect(preview_path).to eq '/tmp/xxx_my_photo.pdf'
        end
      end

      describe 'private method upload preview' do

        let(:s3_object) { double 'S3 Object' }
        let(:kase) { jpg_case_attachment.case }

        it 'uploads the file to s3' do
          expect(CASE_UPLOADS_S3_BUCKET).to receive(:object).with("#{kase.id}/response_previews/my_photo.pdf").and_return(s3_object)
          expect(s3_object).to receive(:upload_file).with('xxx')

          jpg_case_attachment.__send__(:upload_preview, 'xxx', 0)
        end

        it 'raises if fails after the maximum number of retries has been reached' do
          expect(CASE_UPLOADS_S3_BUCKET).to receive(:object).with("#{kase.id}/response_previews/my_photo.pdf").and_return(s3_object)
          expect(s3_object).to receive(:upload_file).with('xxx').and_return(false)

          expect {
            jpg_case_attachment.__send__(:upload_preview, 'xxx', 5)
          }.to raise_error RuntimeError, "Max upload retry exceeded for CaseAttachment #{jpg_case_attachment.id}"
        end

        it 'requeues the job if uplaod fails and max retries as not been reached' do
          expect(CASE_UPLOADS_S3_BUCKET).to receive(:object).with("#{kase.id}/response_previews/my_photo.pdf").and_return(s3_object)
          expect(s3_object).to receive(:upload_file).with('xxx').and_return(false)

          expect(PdfMakerJob).to receive(:perform_with_delay).with(jpg_case_attachment.id, 3)
          jpg_case_attachment.__send__(:upload_preview, 'xxx', 2)
        end
      end
    end
  end

end

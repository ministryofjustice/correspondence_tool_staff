# == Schema Information
#
# Table name: case_attachments
#
#  id         :integer          not null, primary key
#  case_id    :integer
#  type       :enum
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  key        :string
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

  describe '#temporary_url' do
    subject do
      create :case_attachment,
             type: 'response',
             key: "#{SecureRandom.hex(16)}/responses/new response.pdf"

    end
    let(:object)        { instance_double(Aws::S3::Object) }
    let(:presigned_url) { instance_double(String, "presigned_url") }

    before do
      allow(CASE_UPLOADS_S3_BUCKET).to receive(:object).with(subject.key)
                                         .and_return(object)
      allow(object).to receive(:presigned_url)
                         .with(:get, expires_in: 60)
                         .and_return(presigned_url)

    end

    it 'creates a pre-signed url that is good for 60s' do
      expect(subject.temporary_url).to be presigned_url
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
end

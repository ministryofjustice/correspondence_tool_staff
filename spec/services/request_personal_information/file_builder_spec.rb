require "rails_helper"

describe RequestPersonalInformation::FileBuilder do
  let(:rpi) { create(:personal_information_request, submission_id: "ABC123") }
  let(:targets) { %i[branston disclosure] }
  let(:builder) { described_class.new(rpi, targets) }
  let(:attachment) { instance_double(RequestPersonalInformation::Attachment, filename: "file.png", file_data: "123456") }
  let(:data) { instance_double(RequestPersonalInformation::Data, attachments: [attachment]) }
  let(:branston_object) { instance_double(Aws::S3::Object, upload_file: nil) }
  let(:disclosure_object) { instance_double(Aws::S3::Object, upload_file: nil) }

  describe "#build" do
    it "uploads file for each target to S3" do
      allow(CASE_UPLOADS_S3_BUCKET).to receive(:object).with("rpi/branston/#{rpi.submission_id}.zip").and_return(branston_object)
      allow(CASE_UPLOADS_S3_BUCKET).to receive(:object).with("rpi/disclosure/#{rpi.submission_id}.zip").and_return(disclosure_object)
      expect(branston_object).to receive(:upload_file)
      expect(disclosure_object).to receive(:upload_file)
      builder.build(data)
    end
  end
end

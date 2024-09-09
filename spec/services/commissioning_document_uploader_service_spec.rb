require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
xdescribe CommissioningDocumentUploaderService do
  let(:responder) { find_or_create :sar_responder }
  let(:kase) { create(:offender_sar_case, responder:) }
  let(:commissioning_document) { create(:commissioning_document) }
  let(:user) { kase.responder }
  let(:filename) { "#{Faker::Internet.slug}.docx" }
  let(:uploads_key) { "uploads/#{kase.id}/requests/#{filename}" }
  let(:uploaded_file) { uploads_key }
  let(:service) do
    described_class.new(
      kase:,
      commissioning_document:,
      current_user: user,
      uploaded_file:,
    )
  end
  let(:attachments) { [create(:commissioning_document_attachment)] }
  let(:uploader) { instance_double(S3Uploader, process_files: attachments) }

  before do
    ActiveJob::Base.queue_adapter = :test
    allow(S3Uploader).to receive(:new).and_return(uploader)
  end

  after(:all) { DbHousekeeping.clean(seed: true) }

  describe "#upload!" do
    context "when action upload" do
      it "calls #process_files on the uploader" do
        service.upload!
        expect(uploader).to have_received(:process_files)
                              .with(uploads_key, :commissioning_document)
      end

      it "returns the attachments created" do
        expect(service.upload!).to eq attachments.first
      end

      it "gives a result of :ok" do
        service.upload!
        expect(service.result).to eq :ok
      end

      it "associated the attachment to the commissioning document" do
        expect {
          service.upload!
        }.to change(commissioning_document, :attachment_id)
      end

      context "when no valid files to upload" do
        let(:uploaded_file) { [] }

        it "returns a result of :blank" do
          service.upload!
          expect(service.result).to eq :blank
        end
      end

      context "when invalid filetype to upload" do
        let(:uploaded_file) { ["test.jpg"] }

        it "returns a result of :blank" do
          service.upload!
          expect(service.result).to eq :blank
        end
      end

      describe "uploader raises an S3 service error" do
        before do
          allow(uploader)
            .to receive(:process_files)
                  .with(uploads_key, :commissioning_document)
                  .and_raise(Aws::S3::Errors::ServiceError.new(:foo, :bar))
        end

        it "returns :error" do
          service.upload!
          expect(service.result).to eq :error
        end
      end

      describe "uploader raises a record invalid error" do
        before do
          allow(uploader)
            .to receive(:process_files)
                  .with(uploads_key, :commissioning_document)
                  .and_raise(ActiveRecord::RecordInvalid)
        end

        it "returns :error" do
          service.upload!
          expect(service.result).to eq :error
        end
      end

      describe "uploader raises an record not unique" do
        before do
          allow(uploader)
            .to receive(:process_files)
                  .with(uploads_key, :commissioning_document)
                  .and_raise(ActiveRecord::RecordNotUnique)
        end

        it "returns :error" do
          service.upload!
          expect(service.result).to eq :error
        end
      end
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll

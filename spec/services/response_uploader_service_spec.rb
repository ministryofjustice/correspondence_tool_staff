require "rails_helper"

describe ResponseUploaderService do
  let(:upload_group)       { "20170615102233" }
  let(:responder)          { find_or_create :foi_responder }
  let(:kase)               { create(:accepted_case, responder:) }
  let(:user)               { kase.responder }
  let(:filename)           { "#{Faker::Internet.slug}.jpg" }
  let(:uploads_key)        { "uploads/#{kase.id}/responses/#{filename}" }
  let(:destination_key)    { "#{kase.id}/responses/#{upload_group}/#{filename}" }
  let(:destination_path)   { "correspondence-staff-case-uploads-testing/#{destination_key}" }
  let(:is_draft_compliant) { true }
  let(:bypass_further_approval) { false }
  let(:uploaded_files)     { [uploads_key] }
  let(:upload_comment)     { nil }
  let(:action)             { "upload" }
  let(:rus)                do
    described_class.new(
      kase:,
      current_user: user,
      bypass_further_approval:,
      action:,
      uploaded_files:,
      upload_comment:,
      bypass_message: "",
      is_compliant: is_draft_compliant,
    )
  end
  let(:rus_with_message) do
    described_class.new(
      kase:,
      current_user: user,
      bypass_further_approval:,
      action:,
      uploaded_files: [uploads_key],
      upload_comment: "This is my upload message",
      bypass_message: "",
      is_compliant: is_draft_compliant,
    )
  end
  let(:attachments) do
    [instance_double(CaseAttachment,
                     filename:)]
  end
  let(:uploader) do
    instance_double(S3Uploader,
                    process_files: attachments)
  end

  before do
    ActiveJob::Base.queue_adapter = :test
    allow(S3Uploader).to receive(:new).and_return(uploader)

    allow(ActionNotificationsMailer).to receive_message_chain(:ready_for_press_or_private_review,
                                                              :deliver_later)
  end

  describe "#upload!" do
    context "with action upload" do
      let(:action) { "upload" }

      it "calls #process_files on the uploader" do
        rus.upload!
        expect(uploader).to have_received(:process_files)
                              .with([uploads_key], :response)
      end

      it "returns the attachments created" do
        expect(rus.upload!).to eq attachments
      end

      it "gives a result of :ok" do
        rus.upload!
        expect(rus.result).to eq :ok
      end

      it "creates a transition" do
        rus.upload!
        transition = kase.transitions.last
        expect(transition.event).to eq "add_responses"
        expect(transition.metadata).to eq({ "filenames" => [filename], "message" => nil })
      end

      it "creates a transition with a message" do
        rus_with_message.upload!
        transition = kase.transitions.last
        expect(transition.event).to eq "add_responses"
        expect(transition.metadata).to eq({ "filenames" => [filename], "message" => "This is my upload message" })
      end

      it "calls add_responses! for non flagged cases" do
        allow(kase.state_machine).to receive(:add_responses!)
        rus.upload!
        expect(kase.state_machine).to have_received(:add_responses!)
      end

      context "and no valid files to upload" do
        let(:uploaded_files) { [] }

        it "returns a result of :blank" do
          rus.upload!
          expect(rus.result).to eq :blank
        end
      end

      describe "uploader raises an S3 service error" do
        before do
          allow(uploader)
            .to receive(:process_files)
                  .with([uploads_key], :response)
                  .and_raise(Aws::S3::Errors::ServiceError.new(:foo, :bar))
        end

        it "returns :error" do
          rus.upload!
          expect(rus.result).to eq :error
        end
      end

      describe "uploader raises a record invalid error" do
        before do
          allow(uploader)
            .to receive(:process_files)
                  .with([uploads_key], :response)
                  .and_raise(ActiveRecord::RecordInvalid)
        end

        it "returns :error" do
          rus.upload!
          expect(rus.result).to eq :error
        end
      end

      describe "uploader raises an record not unique" do
        before do
          allow(uploader)
            .to receive(:process_files)
                  .with([uploads_key], :response)
                  .and_raise(ActiveRecord::RecordNotUnique)
        end

        it "returns :error" do
          rus.upload!
          expect(rus.result).to eq :error
        end
      end
    end
  end

  context "with action upload-flagged" do
    let(:action)  { "upload" }
    let(:kase)    { create :accepted_case, :flagged }

    it "calls add_responses! on state machine" do
      expect(kase.state_machine).to receive(:add_responses!)
      rus.upload!
    end

    it "creates a transition" do
      rus.upload!
      transition = kase.transitions.last
      expect(transition.event).to eq "add_responses"
      expect(transition.metadata).to eq({ "filenames" => [filename], "message" => nil })
    end

    it "creates a transition with a message" do
      rus_with_message.upload!
      transition = kase.transitions.last
      expect(transition.event).to eq "add_responses"
      expect(transition.metadata).to eq({ "filenames" => [filename], "message" => "This is my upload message" })
    end
  end

  context "with action upload-approve" do
    let(:action)  { "upload-approve" }
    let(:kase)    { create :pending_dacu_clearance_case, :flagged_accepted, :dacu_disclosure }
    let(:user)    { kase.approvers.first }

    it "calls upload_response_and_approve! on state machine" do
      expect(kase.state_machine).to receive(:upload_response_and_approve!)
      rus.upload!
    end

    it "creates a transition" do
      rus.upload!
      transition = kase.transitions.last
      expect(transition.event).to eq "upload_response_and_approve"
      expect(transition.metadata).to have_key("filenames")
      expect(transition.metadata["filenames"]).to eq [filename]
      expect(transition.metadata).to have_key("message")
      expect(transition.metadata["message"]).to be_nil
    end

    it "creates a transition with a message" do
      rus_with_message.upload!
      transition = kase.transitions.last
      expect(transition.event).to eq "upload_response_and_approve"
      expect(transition.metadata["filenames"]).to eq [filename]
      expect(transition.metadata).to have_key("message")
      expect(transition.metadata["message"]).to eq "This is my upload message"
    end
  end

  context "with action upload-redraft" do
    let(:action)  { "upload-redraft" }
    let(:kase)    { create :pending_dacu_clearance_case, :flagged_accepted, :dacu_disclosure }
    let(:user)    { kase.approvers.first }

    it "calls upload_response_and_return_for_redraft! on state_machine" do
      expect(kase.state_machine).to receive(:upload_response_and_return_for_redraft!)
      rus.upload!
    end

    it "creates a transition" do
      rus.upload!
      transition = kase.transitions.last
      expect(transition.event).to eq "upload_response_and_return_for_redraft"
      expect(transition.metadata).to have_key("filenames")
      expect(transition.metadata["filenames"]).to eq [filename]
      expect(transition.metadata).to have_key("message")
      expect(transition.metadata["message"]).to be_nil
    end

    it "creates a transition with a message" do
      rus_with_message.upload!
      transition = kase.transitions.last
      expect(transition.event).to eq "upload_response_and_return_for_redraft"
      expect(transition.metadata["filenames"]).to eq [filename]
      expect(transition.metadata).to have_key("message")
      expect(transition.metadata["message"]).to eq "This is my upload message"
    end
  end

  describe "notifying approvers when a case is ready for them to clear" do
    describe "Disclosure" do
      let(:kase)            { create :pending_dacu_clearance_case_flagged_for_press }
      let(:user)            { kase.assigned_disclosure_specialist! }

      context "when clear and upload a response" do
        let(:action) { "upload-approve" }

        it "does send an email" do
          rus.upload!
          expect(rus.result).to eq :ok

          current_info = CurrentTeamAndUserService.new(kase)
          assignment = kase.approver_assignments
                         .for_team(current_info.team)
                         .first

          expect(ActionNotificationsMailer).to have_received(:ready_for_press_or_private_review).with assignment
        end
      end

      context "when upload a response and request redraft" do
        let(:action) { "upload-redraft" }

        it "does not send an email" do
          rus.upload!
          expect(rus.result).to eq :ok
          expect(ActionNotificationsMailer).not_to have_received(:ready_for_press_or_private_review)
        end
      end
    end

    context "when as responder I upload a response" do
      let(:action) { "upload" }

      it "does not send an email" do
        rus.upload!
        expect(rus.result).to eq :ok
        expect(ActionNotificationsMailer).not_to have_received(:ready_for_press_or_private_review)
      end
    end
  end
end

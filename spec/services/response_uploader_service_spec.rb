require 'rails_helper'

describe ResponseUploaderService do

  let(:upload_group)       { '20170615102233' }
  let(:responder)          { create :responder }
  let(:kase)               { create(:accepted_case, responder: responder) }
  let(:user)               { kase.responder }
  let(:filename)           { "#{Faker::Internet.slug}.jpg" }
  let(:uploads_key)        { "uploads/#{kase.id}/responses/#{filename}" }
  let(:destination_key)    { "#{kase.id}/responses/#{upload_group}/#{filename}" }
  let(:destination_path)   { "correspondence-staff-case-uploads-testing/#{destination_key}" }
  let(:rus)                { ResponseUploaderService.new(kase,
                                                         user,
                                                         params,
                                                         action) }
  let(:attachments)        { [instance_double(CaseAttachment,
                                              filename: filename)] }
  let(:uploader)           { instance_double(S3Uploader,
                                             process_files: attachments) }


  let(:params) do
    raw_params = ActionController::Parameters.new(
      {
        "type"           => "response",
        "uploaded_files" => [uploads_key],
        "id"             => kase.id.to_s,
        "controller"     => "cases",
        "action"         => "upload_responses"}
    )
    BypassParamsManager.new(raw_params)
  end


  before(:each) do
    ActiveJob::Base.queue_adapter = :test
    allow(S3Uploader).to receive(:new).and_return(uploader)

    allow(ActionNotificationsMailer).to receive_message_chain(:ready_for_approver_review,
                                                       :deliver_later)
  end

  describe '#upload!' do
    context 'action upload' do

      let(:action) { 'upload' }

      it 'calls #process_files on the uploader' do
        rus.upload!
        expect(uploader).to have_received(:process_files)
                              .with([uploads_key], :response)
      end

      it 'returns the attachments created' do
        expect(rus.upload!).to eq attachments
      end

      it 'gives a result of :ok' do
        rus.upload!
        expect(rus.result).to eq :ok
      end

      it 'calls add_responses! for non flagged cases' do
        allow(kase.state_machine).to receive(:add_responses!)
        rus.upload!
        expect(kase.state_machine).to have_received(:add_responses!)
      end

      context 'No valid files to upload' do
        it 'returns a result of :blank' do
          params.params.delete('uploaded_files')
          rus.upload!
          expect(rus.result).to eq :blank

        end
      end

      describe 'uploader raises an S3 service error' do
        before do
          allow(uploader)
            .to receive(:process_files)
                  .with([uploads_key], :response)
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
                  .with([uploads_key], :response)
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
                  .with([uploads_key], :response)
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
                  .with([uploads_key], :response)
                  .and_raise(Aws::S3::Errors::ServiceError.new(:foo, :bar))
        end

        it 'returns :error' do
          rus.upload!
          expect(rus.result).to eq :error
        end
      end
    end
  end

  context 'action upload-flagged' do

    let(:action)  { 'upload-flagged' }

    it 'calls add_response_to_flagged_case! on state machine' do
      expect(kase.state_machine).to receive(:add_response_to_flagged_case!)
      rus.upload!
    end
  end

  context 'action upload-approve' do

    let(:action)  { 'upload-approve' }

    it 'calls add_response_to_flagged_case! on state machine' do
      expect(kase.state_machine).to receive(:upload_response_and_approve!)
      rus.upload!
    end
  end

  context 'action upload-redraft' do
    let(:action)  { 'upload-redraft' }

    it 'calls upload_response_and_return_for_redraft! on state_machine' do
      expect(kase.state_machine).to receive(:upload_response_and_return_for_redraft!)
      rus.upload!
    end
  end

  describe 'notifying approvers when a case is ready for them to clear' do
    context 'as Disclosure' do

      let(:kase)            { create :pending_dacu_clearance_case_flagged_for_press }
      let(:user)            { kase.assigned_disclosure_specialist }

      context 'clear and upload a response' do
        let(:action)          { 'upload-approve' }

        it 'does send an email' do
          rus.upload!
          expect(rus.result).to eq :ok

          current_info = CurrentTeamAndUserService.new(kase)
          assignment = kase.approver_assignments
                         .for_team(current_info.team)
                         .first

          expect(ActionNotificationsMailer).to have_received(:ready_for_approver_review).with assignment
        end
      end

      context 'upload a response and request redraft' do
        let(:action)          { 'upload-redraft' }

        it 'does not send an email' do
          rus.upload!
          expect(rus.result).to eq :ok
          expect(ActionNotificationsMailer).not_to have_received(:ready_for_approver_review)
        end
      end
    end

    context 'as responder when I upload a response' do
      let(:action)  { 'upload' }

      it 'does not send an email' do
        rus.upload!
        expect(rus.result).to eq :ok
        expect(ActionNotificationsMailer).not_to have_received(:ready_for_approver_review)
      end
    end
  end
end


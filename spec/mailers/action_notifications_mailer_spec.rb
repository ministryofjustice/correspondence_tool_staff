require "rails_helper"

RSpec.describe ActionNotificationsMailer, type: :mailer do
  describe "new_assignment" do
    let(:responding_team) { assignment.team }
    let(:responder)       { responding_team.responders.first }

    context "when FOI case" do
      let(:assigned_case) do
        create :assigned_case,
               name: "Fyodor Ognievich Ilichion",
               received_date: 10.business_days.ago,
               subject: "The anatomy of man"
      end
      let(:assignment)      { assigned_case.responder_assignment }
      let(:mail)            do
        described_class.new_assignment(assignment,
                                       responder.email)
      end

      it "sets the template" do
        expect(mail.govuk_notify_template)
            .to eq "6f4d8e34-96cb-482c-9428-a5c1d5efa519"
      end

      it "personalises the email" do
        allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
        expect(mail.govuk_notify_personalisation)
            .to eq({
              email_subject:
                  "To be accepted - FOI - #{assigned_case.number} - The anatomy of man",
              team_name: assignment.team.name,
              case_current_state: "to be accepted",
              case_number: assigned_case.number,
              case_abbr: "FOI",
              case_received_date: 10.business_days.ago.to_date.strftime(Settings.default_date_format),
              case_subject: "The anatomy of man",
              case_link: edit_case_assignment_url(assigned_case.id, assignment.id),
            })
      end

      it "sets the To address of the email using the provided user" do
        expect(mail.to).to include responder.email
      end
    end

    context "when ICO Appeal" do
      let!(:original_case) do
        create :assigned_case,
               name: "Fyodor Ognievich Ilichion",
               received_date: 10.business_days.ago,
               subject: "The anatomy of man"
      end

      let(:assigned_ico_case) do
        create :awaiting_responder_ico_foi_case,
               original_case:,
               received_date: 10.business_days.ago
      end
      let(:assignment)          { assigned_ico_case.responder_assignment }
      let(:mail)                { described_class.new_assignment(assignment, responder.email) }

      it "personalises the email" do
        allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
        expect(mail.govuk_notify_personalisation)
            .to eq({
              email_subject:
                  "To be accepted - ICO appeal (FOI) - #{assigned_ico_case.number} - The anatomy of man",
              team_name: assignment.team.name,
              case_current_state: "to be accepted",
              case_number: assigned_ico_case.number,
              case_abbr: "ICO appeal (FOI)",
              case_received_date: 10.business_days.ago.to_date.strftime(Settings.default_date_format),
              case_subject: "The anatomy of man",
              case_link: edit_case_assignment_url(assigned_ico_case.id, assignment.id),
            })
      end
    end

    context "when Overturned SAR" do
      let(:original_ico_appeal)         { create :closed_ico_sar_case, :overturned_by_ico }
      let(:original_sar)                { create :closed_sar, subject: "The origin of species" }
      let(:awaiting_responder_ovt_sar)  do
        create :awaiting_responder_ot_ico_sar,
               original_ico_appeal:,
               original_case: original_sar,
               received_date: 10.business_days.ago
      end

      let(:assignment)            { awaiting_responder_ovt_sar.responder_assignment }
      let(:mail)                  { described_class.new_assignment(assignment, responder.email) }

      it "personalises the email" do
        allow(CaseNumberCounter).to receive(:next_for_date).and_return(333, 334, 335)
        expect(mail.govuk_notify_personalisation)
            .to eq({
              email_subject:
                  "To be accepted - ICO overturned (SAR) - #{awaiting_responder_ovt_sar.number} - The origin of species",
              team_name: awaiting_responder_ovt_sar.responding_team.name,
              case_number: awaiting_responder_ovt_sar.number,
              case_current_state: "to be accepted",
              case_abbr: "ICO overturned (SAR)",
              case_received_date: awaiting_responder_ovt_sar.received_date.strftime(Settings.default_date_format),
              case_subject: "The origin of species",
              case_link: edit_case_assignment_url(awaiting_responder_ovt_sar.id, assignment.id),
            })
      end
    end

    context "when deleted case" do
      let(:assigned_case) do
        create :assigned_case,
               name: "Fyodor Ognievich Ilichion",
               received_date: 10.business_days.ago,
               subject: "The anatomy of man"
      end
      let!(:assignment) { assigned_case.responder_assignment }

      it "does not error" do
        assigned_case.destroy!
        expect {
          described_class.new.new_assignment(assignment, responder.email)
        }.not_to raise_error
      end
    end
  end

  describe "ready_for_press_or_private_review" do
    let(:pending_case) do
      create :pending_press_clearance_case,
             name: "Fyodor Ognievich Ilichion",
             received_date: 10.business_days.ago,
             subject: "The anatomy of man"
    end
    let(:assignment)      { pending_case.approver_assignments.for_team(BusinessUnit.press_office).singular }
    let(:approving_team)  { assignment.team }
    let(:approver)        { assignment.user }
    let(:mail)            { described_class.ready_for_press_or_private_review(assignment) }

    it "sets the template" do
      expect(mail.govuk_notify_template)
        .to eq "fe9a1e2a-2707-4e10-bb63-aae142f10382"
    end

    it "personalises the email" do
      allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
      expect(mail.govuk_notify_personalisation)
        .to eq({
          email_subject:
          "Pending clearance - FOI - #{pending_case.number} - The anatomy of man",
          approver_full_name: approver.full_name,
          case_number: pending_case.number,
          case_subject: "The anatomy of man",
          case_type: "FOI",
          case_received_date: 10.business_days.ago.to_date.strftime(Settings.default_date_format),
          case_external_deadline: pending_case.external_deadline.strftime(Settings.default_date_format),
          case_link: case_url(pending_case.id),
        })
    end

    it "sets the To address of the email using the provided user" do
      expect(mail.to).to include approver.email
    end
  end

  describe "notify_information_officers" do
    context "when FOI case" do
      let(:approved_case) do
        create :approved_case,
               name: "Fyodor Ognievich Ilichion",
               received_date: 10.business_days.ago,
               subject: "The anatomy of man"
      end
      let(:assignment)      { approved_case.responder_assignment }
      let(:responding_team) { assignment.team }
      let(:responder)       { approved_case.responder }
      let(:mail)            { described_class.notify_information_officers(approved_case, "Ready to send") }

      it "personalises the email" do
        allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
        expect(mail.govuk_notify_personalisation)
          .to eq({
            email_subject:
              "Ready to send - FOI - #{approved_case.number} - The anatomy of man",
            responder_full_name: assignment.user.full_name,
            case_current_state: "ready to send",
            case_number: approved_case.number,
            case_abbr: "FOI",
            case_received_date: 10.business_days.ago.to_date.strftime(Settings.default_date_format),
            case_subject: "The anatomy of man",
            case_link: case_url(approved_case.id),
            case_draft_deadline: approved_case.internal_deadline.strftime(Settings.default_date_format),
            case_external_deadline: approved_case.external_deadline.strftime(Settings.default_date_format),
          })
      end

      it "sets the To address of the email using the provided user" do
        expect(mail.to).to include assignment.user.email
      end

      context "with a case that still has pending assignments" do
        it "uses the accepted responder assignment" do
          other_responding_team = create(:responding_team, responders: [responder])
          approved_case.assignments << Assignment.new(role: "responding",
                                                      team: other_responding_team,
                                                      state: "pending")
          approved_case.reload
          expect(mail.to).to include responder.email
        end
      end

      context "when ready to send" do
        let(:mail) { described_class.notify_information_officers(approved_case, "Ready to send") }

        it "sets the template" do
          expect(mail.govuk_notify_template)
            .to eq "46dc4848-5ad7-4772-9de4-dd6b6f558e5b"
        end
      end

      context "when redraft" do
        let(:mail) { described_class.notify_information_officers(approved_case, "Redraft requested") }

        it "sets the template" do
          expect(mail.govuk_notify_template)
            .to eq "534f0e07-007f-4a48-99e4-c46a41fbd81f"
        end

        it "personalises the email" do
          allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
          expect(mail.govuk_notify_personalisation)
            .to include(email_subject: "Redraft requested - FOI - #{approved_case.number} - The anatomy of man")
        end
      end

      context "when send back" do
        let(:mail) { described_class.notify_information_officers(approved_case, "Responses have been sent back") }

        it "sets the template" do
          expect(mail.govuk_notify_template)
            .to eq "51ddb4e1-477d-496f-a131-e500c0bc351e"
        end

        it "personalises the email" do
          allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
          expect(mail.govuk_notify_personalisation)
            .to include(case_abbr: "FOI")
        end
      end

      context "when message" do
        let(:mail) { described_class.notify_information_officers(approved_case, "Message received") }

        it "sets the template" do
          expect(mail.govuk_notify_template)
              .to eq "55d7abbc-9042-4646-8835-35a1b2e432c4"
        end

        it "personalises the email" do
          allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
          expect(mail.govuk_notify_personalisation)
              .to include(email_subject: "Message received - FOI - #{approved_case.number} - The anatomy of man")
        end
      end

      context "when case closed" do
        let(:mail) { described_class.notify_information_officers(approved_case, "Case closed") }

        it "sets the template" do
          expect(mail.govuk_notify_template)
              .to eq "0f89383e-cee2-4a10-bc47-97879d1f6dc4"
        end
      end
    end

    context "when overturned SAR" do
      let(:original_ico_appeal)   { create :closed_ico_sar_case, :overturned_by_ico }
      let(:original_sar)          { create :closed_sar, subject: "The origin of species" }
      let(:closed_ovt_sar)        do
        create :closed_ot_ico_sar,
               original_ico_appeal:,
               original_case: original_sar,
               received_date: 10.business_days.ago
      end
      let(:mail) { described_class.notify_information_officers(closed_ovt_sar, "Case closed") }

      it "sets the template" do
        expect(mail.govuk_notify_template)
          .to eq "0f89383e-cee2-4a10-bc47-97879d1f6dc4"
      end

      it "personalises the email" do
        allow(CaseNumberCounter).to receive(:next_for_date).and_return(333, 334, 335)

        expect(mail.govuk_notify_personalisation)
          .to eq({
            email_subject: "Case closed - ICO overturned (SAR) - #{closed_ovt_sar.number} - The origin of species",
            responder_full_name: closed_ovt_sar.responder.full_name,
            case_current_state: "closed",
            case_number: closed_ovt_sar.number,
            case_subject: "The origin of species",
            case_abbr: "ICO overturned (SAR)",
            case_received_date: 10.business_days.ago.to_date.strftime(Settings.default_date_format),
            case_external_deadline: closed_ovt_sar.external_deadline.strftime(Settings.default_date_format),
            case_link: case_url(closed_ovt_sar),
            case_draft_deadline: closed_ovt_sar.internal_deadline.strftime(Settings.default_date_format),

          })
      end
    end

    context "when no assigned user" do
      let(:approved_case) do
        create :approved_case,
               name: "Fyodor Ognievich Ilichion",
               received_date: 10.business_days.ago,
               subject: "The anatomy of man"
      end
      let(:assignment) { approved_case.responder_assignment }

      it "does not error" do
        approved_case.responder_assignment.update!(state: "pending")

        expect {
          described_class.new.notify_information_officers(approved_case, "Ready to send")
        }.not_to raise_error
      end
    end
  end

  describe "notify_team" do
    let(:kase) do
      create :closed_sar,
             name: "Semyon Aleksandrovich Romanov",
             received_date: 10.business_days.ago,
             subject: "Lightness of not being"
    end
    let(:assignment)      { approved_case.responder_assignment }
    let(:responding_team) { assignment.team }
    let(:responder)       { approved_case.responder }
    let(:managing_team)   { kase.managing_team }
    let(:mail)            do
      described_class.notify_team(managing_team,
                                  kase,
                                  "Case closed")
    end

    it "personalises the email" do
      # allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
      expect(mail.govuk_notify_personalisation)
        .to eq({
          email_subject:
            "Case closed - SAR - #{kase.number} - Lightness of not being",
          name: managing_team.name,
          case_number: kase.number,
          case_abbr: "SAR",
          case_received_date: kase.received_date.strftime(Settings.default_date_format),
          case_subject: "Lightness of not being",
          case_link: case_url(kase.id),
          case_external_deadline: kase.external_deadline.strftime(Settings.default_date_format),
        })
    end

    it "sets the To address to the email of the team" do
      expect(mail.to).to include managing_team.email
    end
  end

  describe "case_assigned_to_another_user" do
    let(:accepted_case) do
      create :accepted_case,
             name: "Fyodor Ognievich Ilichion",
             received_date: 10.business_days.ago,
             subject: "The anatomy of man"
    end
    let(:responding_team) { accepted_case.responding_team }
    let(:responder)       { responding_team.responders.first }
    let(:mail)            do
      described_class
                                .case_assigned_to_another_user(accepted_case,
                                                               responder)
    end

    it "sets the template" do
      expect(mail.govuk_notify_template)
        .to eq "1e26c707-e7e3-4b21-835d-1241da6ea251"
    end

    it "personalises the email" do
      allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
      expect(mail.govuk_notify_personalisation)
        .to eq({
          email_subject:
            "Assigned to you - FOI - #{accepted_case.number} - The anatomy of man",
          user_name: responder.full_name,
          case_number: accepted_case.number,
          case_abbr: "FOI",
          case_received_date: 10.business_days.ago.to_date.strftime(Settings.default_date_format),
          case_subject: "The anatomy of man",
          case_link: case_url(accepted_case.id),
          case_external_deadline: accepted_case.external_deadline.strftime(Settings.default_date_format),
        })
    end

    it "sets the To address of the email using the provided user" do
      expect(mail.to).to include responder.email
    end
  end

  describe "commissioning_email" do
    let(:commissioning_document) { create :commissioning_document }
    let(:email_address) { "test@test.com" }
    let(:kase_number) { "12345" }
    let(:mail) { described_class.commissioning_email(commissioning_document, kase_number, email_address) }

    it "sets the template" do
      expect(mail.govuk_notify_template)
        .to eq "94b66c61-feff-42f5-950d-d0af0a8205ef"
    end

    it "personalises the email" do
      expect(mail.govuk_notify_personalisation[:email_address]).to eq email_address
      expect(mail.govuk_notify_personalisation[:deadline_text]).to eq I18n.t("mailer.commissioning_email.deadline", date: commissioning_document.deadline)
      expect(mail.govuk_notify_personalisation[:email_subject]).to include "Subject Access Request"
    end

    it "sets the To address of the email using the provided user" do
      expect(mail.to).to include email_address
    end

    it "creates a DataRequestEmail record" do
      expect {
        mail.deliver
      }.to change(DataRequestEmail, :count).by 1
    end

    context "when email is retried" do
      it "doesn't create a new data_request_email record" do
        create(:data_request_email, email_address:, data_request: commissioning_document.data_request)

        expect {
          mail.deliver
        }.to change(DataRequestEmail, :count).by 0
      end
    end

    describe "#set_notify_id" do
      let(:data_request_email) { create(:data_request_email) }
      let(:notify_id) { "35daaa7a-2859-4c39-a5f2-bfdb17a053f4" }
      let(:message) do
        OpenStruct.new(
          govuk_notify_response: OpenStruct.new(id: notify_id),
        )
      end

      it "updates object with notify ID" do
        mailer = described_class.new
        allow(mailer).to receive(:message).and_return(message)
        allow(mailer).to receive(:data_request_email).and_return(data_request_email)

        mailer.send(:set_notify_id)
        expect(data_request_email.notify_id).to eq notify_id
      end
    end
  end

  describe "rpi_email" do
    let(:rpi) { create :personal_information_request }
    let(:target) { :branston }
    let(:mail) { described_class.rpi_email(rpi, target) }

    it "sets the template" do
      expect(mail.govuk_notify_template)
        .to eq "5e63f6c1-e7d6-47da-845c-fa47343ab882"
    end

    it "personalises the email" do
      expect(mail.govuk_notify_personalisation[:content]).to eq rpi.attachment_url(target)
    end

    it "sets the To address of the email based on the target" do
      expect(mail.to).to include PersonalInformationRequest.email_for_target(target)
    end
  end
end

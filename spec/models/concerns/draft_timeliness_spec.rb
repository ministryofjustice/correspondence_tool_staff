require "rails_helper"

module DraftTimeliness
  describe ResponseAdded do
    let(:kase) do
      create :pending_dacu_clearance_case,
             when_response_uploaded: 1.working.day.ago
    end

    let(:new_response) do
      response = build(:correspondence_response,
                       type: "response",
                       user_id: kase.responder.id)
      kase.attachments.push(response)
      response
    end

    it "updates using the last add_responses event" do
      new_transition = create :case_transition_pending_dacu_clearance,
                              case: kase,
                              filenames: new_response.filename

      expect(kase.date_draft_compliant).to be_nil

      kase.log_compliance_date!

      expect(kase.date_draft_compliant)
        .to eq new_transition.created_at.to_date
    end

    it "updates using the last add_response_to_flagged_case event" do
      new_transition = create :case_transition,
                              case: kase,
                              event: "add_response_to_flagged_case",
                              to_state: "pending_dacu_clearance",
                              filenames: new_response.filename

      expect(kase.date_draft_compliant).to be_nil

      kase.log_compliance_date!

      expect(kase.date_draft_compliant)
        .to eq new_transition.created_at.to_date
    end

    context "when draft deadline has already been set" do
      let(:kase) { create :redrafting_case }

      it "does not update" do
        expect(kase.date_draft_compliant).to be_present

        expect {
          kase.log_compliance_date!
        }.not_to change(kase, :date_draft_compliant)
      end
    end
  end

  describe ProgressedForClearance do
    let(:kase) { create :pending_dacu_clearance_sar }

    it "updates using the last progress_for_clearance event" do
      new_transition = create :case_transition_progress_for_clearance,
                              case: kase

      expect(kase.date_draft_compliant).to be_nil

      kase.log_compliance_date!

      expect(kase.date_draft_compliant)
        .to eq new_transition.created_at.to_date
    end

    context "when draft deadline has already been set" do
      let(:kase) { create :amends_requested_sar }

      it "does not update" do
        expect(kase.date_draft_compliant).to be_present

        expect {
          kase.log_compliance_date!
        }.not_to change(kase, :date_draft_compliant)
      end
    end
  end
end

require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe CaseCreateService do
  let(:manager) { create :manager, managing_teams: [team_dacu] }
  let!(:team_dacu) { find_or_create :team_dacu }
  let!(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }

  let(:unsaved_sar_ir_case) { build(:sar_internal_review) }

  let(:regular_params) do
    ActionController::Parameters.new(
      {
        foi: {
          type: "Standard",
          requester_type: "member_of_the_public",
          name: "A. Member of Public",
          postal_address: "102 Petty France",
          email: "member@public.com",
          subject: "FOI request from controller spec",
          message: "FOI about prisons and probation",
          received_date_dd: Time.zone.today.day.to_s,
          received_date_mm: Time.zone.today.month.to_s,
          received_date_yyyy: Time.zone.today.year.to_s,
          delivery_method: :sent_by_email,
          uploaded_request_files: ["uploads/71/request/request.pdf"],
          flag_for_disclosure_specialists: "no",
        },
      },
    )
  end
  let(:ico_overturned_params) do
    {
      "external_deadline_dd" => deadline.day.to_s,
      "external_deadline_mm" => deadline.month.to_s,
      "external_deadline_yyyy" => deadline.year.to_s,
      "reply_method" => "send_by_email",
      "email" => "stephen@stephenrichards.eu",
      "postal_address" => "",
    }
  end

  describe "#call" do
    context "when unflagged FOI case" do
      let(:params) do
        regular_params.merge flag_for_disclosure_specialists: "no"
      end
      let(:ccs) { described_class.new(user: manager, case_type: Case::FOI::Standard, params: params[:foi]) }

      it "creates a case" do
        expect { ccs.call }.to change(Case::Base, :count).by 1
      end

      it "uses the params provided" do
        ccs.call

        created_case = Case::Base.first
        expect(created_case.requester_type).to eq "member_of_the_public"
        expect(created_case.name).to eq "A. Member of Public"
        expect(created_case.postal_address).to eq "102 Petty France"
        expect(created_case.email).to eq "member@public.com"
        expect(created_case.subject).to eq "FOI request from controller spec"
        expect(created_case.message).to eq "FOI about prisons and probation"
        expect(created_case.received_date).to eq Time.zone.today
      end

      it 'sets the result to "assign_responder"' do
        ccs.call
        expect(ccs.result).to eq :assign_responder
      end

      it "returns true" do
        expect(ccs.call).to eq true
      end
    end

    context "when flagged FOI case" do
      let(:params) do
        regular_params["foi"]["flag_for_disclosure_specialists"] = "yes"
        regular_params
      end
      let(:ccs) { described_class.new(user: manager, case_type: Case::FOI::Standard, params: params[:foi]) }

      it "creates a case" do
        expect { ccs.call }.to change(Case::Base, :count).by 1
      end

      it "uses the params provided" do
        ccs.call

        created_case = Case::Base.first
        expect(created_case.requester_type).to eq "member_of_the_public"
        expect(created_case.name).to eq "A. Member of Public"
        expect(created_case.postal_address).to eq "102 Petty France"
        expect(created_case.email).to eq "member@public.com"
        expect(created_case.subject).to eq "FOI request from controller spec"
        expect(created_case.message).to eq "FOI about prisons and probation"
        expect(created_case.received_date).to eq Time.zone.today
      end

      it "flags for disclosure specialists" do
        ccs.call
        created_case = Case::Base.first
        expect(created_case.approver_assignments.first.team)
          .to eq team_dacu_disclosure
      end

      it 'sets the result to "assign_responder"' do
        ccs.call
        expect(ccs.result).to eq :assign_responder
      end

      it "returns true" do
        expect(ccs.call).to eq true
      end
    end

    context "when ICO case" do
      let(:received)          { 0.business_days.ago }
      let(:deadline)          { 28.business_days.after(received) }
      let(:internal_deadline) { 10.business_days.before(deadline) }
      let(:foi)               { create :closed_case }
      let(:params) do
        ActionController::Parameters.new(
          { "ico" => {
            "type" => "Case::ICO::FOI",
            # 'original_case_type'      => 'FOI',
            "original_case_id" => foi.id,
            "ico_officer_name" => "Ian C. Oldman",
            "ico_reference_number" => "ABC1344422",
            "received_date_dd" => received.day.to_s,
            "received_date_mm" => received.month.to_s,
            "received_date_yyyy" => received.year.to_s,
            "external_deadline_dd" => deadline.day.to_s,
            "external_deadline_mm" => deadline.month.to_s,
            "external_deadline_yyyy" => deadline.year.to_s,
            "internal_deadline_dd" => internal_deadline.day.to_s,
            "internal_deadline_mm" => internal_deadline.month.to_s,
            "internal_deadline_yyyy" => internal_deadline.year.to_s,
            "message" => "AAAAA",
          } },
        )
      end
      let(:ccs) { described_class.new(user: manager, case_type: Case::ICO::FOI, params: params[:ico]) }
      let(:created_ico_case) { Case::ICO::FOI.last }

      it "uses the params provided" do
        ccs.call

        created_case = Case::Base.find(ccs.case.id)
        expect(created_case).to be_instance_of(Case::ICO::FOI)
        expect(created_ico_case.ico_officer_name).to eq "Ian C. Oldman"
        expect(created_case.ico_reference_number).to eq "ABC1344422"
        expect(created_case.external_deadline).to eq deadline.to_date
        expect(created_case.internal_deadline).to eq(10.business_days.before(deadline).to_date)
        expect(created_case.message).to eq "AAAAA"
        expect(created_case.subject).to eq foi.subject
        expect(created_case.current_state).to eq "unassigned"
      end

      it "sets the workflow to trigger" do
        ccs.call
        expect(created_ico_case.workflow).to eq "trigger"
      end

      it "assigns the case to disclosure for approval" do
        ccs.call
        approving_assignments = created_ico_case.assignments.approving
        expect(approving_assignments.size).to eq 1
        assignment = approving_assignments.first
        expect(assignment.state).to eq "pending"
        expect(assignment.team).to eq BusinessUnit.dacu_disclosure
      end
    end

    context "when OverturnedSAR" do
      before(:all) do
        @original_ico_appeal = create(:closed_ico_sar_case)
      end

      after(:all) do
        DbHousekeeping.clean(seed: true)
      end

      let(:deadline)            { 1.month.from_now.to_date }
      let(:original_ico_appeal) { @original_ico_appeal }
      let(:original_case)       { original_ico_appeal.original_case }
      let(:ccs)                 { described_class.new(user: manager, case_type: Case::OverturnedICO::SAR, params: params[:overturned_sar]) }
      let(:params) do
        ActionController::Parameters.new(
          {
            correspondence_type: "overturned_sar",
            overturned_sar: ico_overturned_params.merge(
              original_ico_appeal_id: original_ico_appeal.id.to_s,
              original_case_id: original_case.id,
              received_date_dd: original_ico_appeal.date_ico_decision_received_dd,
              received_date_mm: original_ico_appeal.date_ico_decision_received_mm,
              received_date_yyyy: original_ico_appeal.date_ico_decision_received_yyyy,
            ),
            commit: "Create case",
          },
        )
      end
      let(:new_case) { Case::OverturnedICO::SAR.last }

      it "creates a case with the specified params" do
        ccs.call
        expect(new_case).to be_valid
        expect(new_case.original_ico_appeal).to eq original_ico_appeal
        expect(new_case.original_case).to eq original_case
        expect(new_case.received_date).to eq original_ico_appeal.date_ico_decision_received
        expect(new_case.external_deadline).to eq deadline
        expect(new_case.reply_method).to eq "send_by_email"
        expect(new_case.email).to eq "stephen@stephenrichards.eu"
      end

      it "sets the workflow to standard" do
        ccs.call
        expect(new_case.workflow).to eq "standard"
      end

      it "sets the current state to unassigned" do
        ccs.call
        expect(new_case.current_state).to eq "unassigned"
      end

      it "sets the original case" do
        ccs.call
        expect(new_case.original_case).to eq original_case
      end

      it "sets the received date" do
        ccs.call
        expect(new_case.received_date)
          .to eq original_ico_appeal.date_ico_decision_received
      end

      it "sets the escalation date to 20 working days before the external deadline" do
        ccs.call
        kase = Case::OverturnedICO::SAR.last
        expect(kase.internal_deadline).to eq 20.business_days.before(kase.external_deadline)
      end

      it "calls #link_related_cases on the newly created case" do
        expect_any_instance_of(Case::OverturnedICO::SAR) # rubocop:disable RSpec/AnyInstance
          .to receive(:link_related_cases)
        ccs.call
      end

      context "and invalid case type for original ico appeal" do
        let(:original_ico_appeal) { create :closed_ico_foi_case }

        it "errors" do
          ccs.call

          expect(ccs.case.errors[:original_ico_appeal])
            .to eq ["is not an ICO appeal for a SAR case"]
        end
      end
    end

    context "when non trigger OverturnedFOI" do
      before(:all) do
        @original_ico_appeal = create(:closed_ico_foi_case)
      end

      after(:all) do
        DbHousekeeping.clean(seed: true)
      end

      let(:deadline)            { 1.month.from_now.to_date }
      let(:original_ico_appeal) { @original_ico_appeal }
      let(:original_case)       { original_ico_appeal.original_case }
      let!(:ccs) { described_class.new(user: manager, case_type: Case::OverturnedICO::FOI, params: params[:overturned_foi]) }
      let(:params) do
        ActionController::Parameters.new(
          {
            correspondence_type: "overturned_sar",
            overturned_foi: ico_overturned_params.merge(
              original_ico_appeal_id: original_ico_appeal.id.to_s,
              original_case_id: original_case.id,
              received_date_dd: original_ico_appeal.date_ico_decision_received_dd,
              received_date_mm: original_ico_appeal.date_ico_decision_received_mm,
              received_date_yyyy: original_ico_appeal.date_ico_decision_received_yyyy,
            ),
            commit: "Create case",
          },
        )
      end
      let(:new_case) { Case::OverturnedICO::FOI.last }

      it "creates a case with the specified params" do
        ccs.call
        expect(ccs.result).to eq(:assign_responder)
        expect(new_case).to be_valid
        expect(new_case.original_ico_appeal).to eq original_ico_appeal
        expect(new_case.original_case).to eq original_case
        expect(new_case.received_date).to eq original_ico_appeal.date_ico_decision_received
        expect(new_case.external_deadline).to eq deadline
        expect(new_case.reply_method).to eq "send_by_email"
        expect(new_case.email).to eq "stephen@stephenrichards.eu"
      end

      it "sets the workflow to standard" do
        ccs.call
        expect(new_case.workflow).to eq "standard"
      end

      it "sets the current state to unassigned" do
        ccs.call
        expect(new_case.current_state).to eq "unassigned"
      end

      it "sets the original case" do
        ccs.call
        expect(new_case.original_case).to eq original_case
      end

      it "sets the received date" do
        ccs.call
        expect(new_case.received_date)
          .to eq original_ico_appeal.date_ico_decision_received
      end

      it "sets the escalation date to 20 working days before the external deadline" do
        ccs.call
        kase = Case::OverturnedICO::FOI.last
        expect(kase.internal_deadline).to eq 20.business_days.before(kase.external_deadline, holidays: ::BusinessTimeConfig.additional_bank_holidays)
      end

      it "calls #link_related_cases on the newly created case" do
        expect_any_instance_of(Case::OverturnedICO::FOI) # rubocop:disable RSpec/AnyInstance
          .to receive(:link_related_cases)
        ccs.call
      end

      context "and invalid case type for original ico appeal" do
        let(:original_ico_appeal) { create :closed_ico_sar_case }

        it "errors" do
          ccs.call

          expect(ccs.case.errors[:original_ico_appeal])
            .to eq ["is not an ICO appeal for a FOI case"]
        end
      end

      context "and Trigger Overturned FOI case" do
        before do
          params[:overturned_foi][:flag_for_disclosure_specialists] = "yes"
        end

        it "sets the workflow to trigger" do
          ccs.call
          expect(new_case.workflow).to eq "trigger"
        end
      end
    end
  end

  context "when invalid case params" do
    let(:params) do
      regular_params[:foi][:name] = nil
      regular_params
    end
    let(:ccs) { described_class.new(user: manager, case_type: Case::FOI::Standard, params: params[:foi]) }

    it 'sets the result to "error"' do
      ccs.call
      expect(ccs.result).to eq :error
    end

    it "returns false" do
      expect(ccs.call).to eq false
    end
  end

  context "when prebuilt case for stepped cases" do
    let(:minimal_params) do
      ActionController::Parameters.new({
        flag_for_disclosure_specialists: "yes",
      })
    end

    let(:ccs) { described_class.new(user: manager, case_type: Case::SAR::InternalReview, params: minimal_params, prebuilt_case: unsaved_sar_ir_case) }

    it "can create a case from a prebuilt case - i.e. assignments and saving" do
      expect(unsaved_sar_ir_case.workflow).to eq("standard")

      ccs.call
      new_case = Case::SAR::InternalReview.last

      expect(new_case.id).to match(unsaved_sar_ir_case.id)
      expect(new_case.workflow).to match("trigger")
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll

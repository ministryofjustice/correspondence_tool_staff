require "rails_helper"

RSpec.describe CasesController, type: :controller do
  let(:responder) { find_or_create :foi_responder }
  let(:another_responder) { create :responder }
  let(:responding_team) { responder.responding_teams.first }
  let(:co_responder) do
    create :responder,
           responding_teams: [responding_team]
  end
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }
  let(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  let(:approver_responder) do
    create :approver_responder,
           responding_teams: [responding_team],
           approving_team: team_dacu_disclosure
  end
  let(:assigned_case) do
    create :assigned_case,
           responding_team:
  end
  let(:accepted_case) do
    create :accepted_case,
           responder:,
           responding_team:
  end
  let(:pending_dacu_clearance_case) do
    create :pending_dacu_clearance_case,
           responding_team:
  end
  let(:case_accepted_by_approver_responder) do
    create :accepted_case,
           :flagged_accepted,
           approver: approver_responder,
           responder: approver_responder,
           responding_team:
  end
  let(:case_only_accepted_for_approving) do
    create :accepted_case,
           :flagged_accepted,
           approver: approver_responder,
           responder: another_responder,
           responding_team: another_responder.responding_teams.first
  end

  describe "#set_cases" do
    before do
      user = find_or_create :foi_responder
      sign_in user
      get :show, params: { id: assigned_case.id }
    end

    it "instantiates the case" do
      expect(assigns(:case)).to eq assigned_case
    end

    it "decorates the collection of case transitions" do
      expect(assigns(:case_transitions)).to be_an_instance_of(PaginatingDecorator)
      expect(assigns(:case_transitions).map(&:class)).to eq [CaseTransitionDecorator, CaseTransitionDecorator]
    end
  end

  describe "#set_assignments" do
    context "when current user is only in responder team" do
      it "instantiates the assignments for responders" do
        sign_in responder
        get :show, params: { id: accepted_case.id }
        expect(assigns(:assignments)).to eq [accepted_case.responder_assignment]
      end
    end

    context "when current user is another responder on same team" do
      let(:kase) { accepted_case }

      it "instantiates responding assignment" do
        sign_in co_responder
        get :show, params: { id: kase.id }
        expect(assigns(:assignments)).to eq [kase.responder_assignment]
      end
    end

    context "when current_user is in both responder and approver team" do
      it "instantiates both the assignments for responders and approvers" do
        kase = case_accepted_by_approver_responder
        sign_in approver_responder
        get :show, params: { id: kase.id }
        expect(assigns(:assignments)).to eq [kase.responder_assignment,
                                             kase.approver_assignments.first]
      end
    end

    context "when current user is responder on a different team" do
      let(:kase) { case_only_accepted_for_approving }

      it "does not instantiate responding assignment" do
        sign_in approver_responder
        get :show, params: { id: kase.id }
        expect(assigns(:assignments)).to eq [kase.approver_assignments.first]
      end
    end

    it "instantiates the assignments for approvers" do
      sign_in disclosure_specialist
      get :show, params: { id: pending_dacu_clearance_case.id }
      expect(assigns(:assignments)).to eq [pending_dacu_clearance_case.approver_assignments.first]
    end
  end

  # Other actions tested in controllers/cases_controller/*_spec.rb
end

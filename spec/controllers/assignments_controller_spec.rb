require 'rails_helper'


RSpec.describe AssignmentsController, type: :controller do
  let(:manager)           { create :manager }
  let(:assigned_case)     { create :assigned_case }
  let(:assignment)        { assigned_case.responder_assignment }
  let(:unassigned_case)   { create :case }
  let(:responding_team)   { assigned_case.responding_team }
  let(:responder)         { responding_team.responders.first }
  let(:another_responder) { create :responder, responding_teams: [responding_team] }
  let(:approver)          { create :approver }
  let(:approving_team)    { approver.approving_team }
  let(:press_officer)     { create :press_officer }
  let(:press_office)      { press_officer.approving_team }
  let(:accept_assignment_params) do
    {
      id: assignment.id,
      case_id: assigned_case.id,
      assignment: { state: 'accepted' }
    }
  end
  let(:reject_assignment_params) do
    {
      id: assignment.id,
      case_id: assigned_case.id,
      assignment: {
        state: 'rejected',
        reasons_for_rejection: rejection_message,
      },
    }
  end

  let(:rejection_message) do |_example|
    'rejection test #{example.description}'
  end

  let(:unknown_assignment_params) do
    {
      id: assignment.id,
      case_id: assigned_case.id,
      assignment: { state: 'unknown' },
    }
  end
  let(:assigned_case_flagged) { create :assigned_case, :flagged,
                                       approving_team: approving_team }
  let(:assignment)            { assigned_case.responder_assignment }

  let(:assigned_case_trigger) { create :assigned_case, :flagged_accepted,
                                       approver: approver }



  context 'as an anonymous user' do
    describe 'PATCH accept_or_reject' do
      before do
        patch :accept_or_reject,
          params: {
            id: assignment.id,
            case_id: assignment.case.id,
            assignment: { state: 'accepted' }
          }
      end

      it 'does not update state' do
        expect(assignment.state).to eq 'pending'
      end

      it 'redirects to sign in page' do
        expect(response).to redirect_to new_user_session_path
      end
    end
  end

  context 'as an authenticated assigner' do
    before { sign_in manager }

    describe 'PATCH accept_or_reject' do
      context 'accepting' do
        it 'does not call #accept' do
          allow(assignment).to receive(:accept)
          patch :accept_or_reject, params: accept_assignment_params
          expect(assignment).not_to have_received(:accept)
        end

        it 'does not update state' do
          patch :accept_or_reject, params: accept_assignment_params
          expect(assignment.reload.state).to eq 'pending'
        end

        it 'redirects to application root' do
          patch :accept_or_reject, params: accept_assignment_params
          expect(response).to redirect_to manager_root_path
        end
      end

      context 'rejecting' do
        it 'does not call #reject' do
          allow(assignment).to receive(:reject)
          patch :accept_or_reject, params: reject_assignment_params
          expect(assignment).not_to have_received(:reject)
                                      .with(rejection_message)
        end

        it 'redirects to application root' do
          patch :accept_or_reject, params: reject_assignment_params
          expect(response).to redirect_to manager_root_path
        end
      end
    end
  end

  context 'as an authenticated responder' do
    let(:assignment_params) { { assignment: { state: 'accept' } } }

    before { sign_in responder }

    describe 'PATCH accept_or_reject' do
      before do
        stub_s3_uploader_for_all_files!

        # allow(Assignment).to receive(:find).
        #                        with(assignment.id.to_s).
        #                        and_return(assignment)
        # allow(Assignment).to receive(:find).
        #                        with(assignment.id).
        #                        and_return(assignment)
      end

      context 'accepting' do
        let(:assignment_params) { { assignment: { state: 'accepted' } } }

        it 'calls #accept' do
          expect_any_instance_of(Assignment).to receive(:accept) do |subject_assignment|
            expect(subject_assignment.id).to eq assignment.id
          end
          patch :accept_or_reject, params: accept_assignment_params
        end

        it 'updates state' do
          patch :accept_or_reject, params: accept_assignment_params
          expect(assignment.reload.state).to eq 'accepted'
        end

        it 'redirects to case detail page' do
          patch :accept_or_reject, params: accept_assignment_params
          expect(response).to redirect_to(
                                case_path assigned_case,
                                          accepted_now: true
                              )
        end
      end

      context 'rejecting' do
        it 'calls #reject' do
          expect_any_instance_of(Assignment).to receive(:reject).with(responder, rejection_message) do |subject_assignment|
            expect(subject_assignment.id).to eq assignment.id
          end
          patch :accept_or_reject, params: reject_assignment_params
        end

        it 'redirects to show_rejected page' do
          patch :accept_or_reject, params: reject_assignment_params
          expect(response).to redirect_to(
                                 case_assignments_show_rejected_path(
                                   assigned_case,
                                   rejected_now: true
                                 )
                               )
        end

        it 'requires a reason for rejecting' do
          patch :accept_or_reject, params: reject_assignment_params.merge(
                  assignment: {
                                reasons_for_rejection: '',
                                state: 'rejected'
                              }
                )
          expect(response).to render_template(:edit)
        end

      end

      it 'does not allow unknown states' do
        expect { patch :accept_or_reject, params: unknown_assignment_params }.
          to raise_error(ArgumentError, "'unknown' is not a valid state")
      end
    end
  end

  describe '#accept' do
    context 'using dummy service' do
      let(:assignment) { assigned_case_flagged.approver_assignments.first }
      let(:params)     { { case_id: assigned_case_flagged.id, id: assignment.id} }
      let(:service)    { double(CaseAcceptApproverAssignmentService, call: true) }

      before do
        allow(CaseAcceptApproverAssignmentService)
          .to receive(:new).and_return(service)
      end

      context 'as an approver' do
        before do
          sign_in approver
        end

        it 'uses the service', js: true do
          patch :accept, params: params, xhr: true
          expect(CaseAcceptApproverAssignmentService)
            .to have_received(:new)
                  .with(user: approver, assignment: assignment)
        end

        context 'service succeeds' do
          before do
            allow(service).to receive(:call).and_return(true)
          end

          it 'records success' do
            patch :accept, params: params, xhr: true
            expect(assigns(:success)).to be true
          end

          it 'sets the message to success' do
            patch :accept, params: params, xhr: true
            expect(assigns(:message)).to eq 'Case taken on'
          end

          it 'renders the view' do
            patch :accept, params: params, xhr: true
            expect(response).to have_rendered('assignments/accept')
          end
        end

        context 'assignment is already accepted by user' do
          before do
            allow(service).to receive(:call).and_return(false)
            allow(service).to receive(:result).and_return(:not_pending)
            assignment.user = approver
            assignment.accepted!
            assignment.save!
          end

          it 'records success' do
            patch :accept, params: params, xhr: true
            expect(assigns(:success)).to be true
          end

          it 'sets the message to success' do
            patch :accept, params: params, xhr: true
            expect(assigns(:message)).to eq 'Case taken on'
          end

          it 'renders the view' do
            patch :accept, params: params, xhr: true
            expect(response).to have_rendered('assignments/accept')
          end
        end


        context 'assignment is already accepted by another user' do
          let(:another_approver) { create :approver,
                                          approving_team: approving_team }

          before do
            allow(service).to receive(:call).and_return(false)
            allow(service).to receive(:result).and_return(:not_pending)
            assignment.user = another_approver
            assignment.accepted!
            assignment.save!
          end

          it 'records failure' do
            patch :accept, params: params, xhr: true
            expect(assigns(:success)).to be false
          end

          it 'sets the message to already_accepted' do
            patch :accept, params: params, xhr: true
            expect(assigns(:message))
              .to eq "Case already accepted by #{another_approver.full_name}"
          end

          it 'renders the view' do
            patch :accept, params: params, xhr: true
            expect(response).to have_rendered('assignments/accept')
          end
        end
      end
    end

    context 'case is in unassigned state' do
      it 'succeeds' do
        sign_in approver
        kase = create :case
        assignment = create :approver_assignment, case_id: kase.id, team: approving_team
        expect(kase.current_state).to eq 'unassigned'
        patch :accept, params: {case_id: kase.id, id: assignment.id}, xhr: true
        expect(assignment.reload.user_id).to eq approver.id
      end
    end
  end

  describe '#unaccept' do
    let(:assignment) { assigned_case_trigger.approver_assignments.first }
    let(:params)     { { case_id: assigned_case_trigger.id, id: assignment.id} }
    let(:service)    { double(CaseUnacceptApproverAssignmentService, call: true) }

    before do
      allow(CaseUnacceptApproverAssignmentService)
        .to receive(:new).and_return(service)
    end

    context 'as an approver' do
      before do
        sign_in approver
      end

      it 'uses the service', js: true do
        patch :unaccept, params: params, xhr: true
        expect(CaseUnacceptApproverAssignmentService)
          .to have_received(:new).with(assignment: assignment)
      end

      context 'service succeeds' do
        before do
          allow(service).to receive(:call).and_return(true)
        end

        it 'renders the view' do
          patch :unaccept, params: params, xhr: true
          expect(response).to have_rendered('assignments/unaccept')
        end
      end
    end
  end

  describe '#take_case_on' do
    context 'as an anonymous user' do
      it 'redirects to login page' do
        patch :take_case_on, params: { id: assignment.id, case_id: assigned_case.id }
        expect(response).to redirect_to new_user_session_path
      end
    end

    context 'as a press office approver' do

      let(:press_officer)  { create :press_officer }
      let(:service) { double CaseFlagForClearanceService }


      before(:each) { sign_in press_officer }

      it 'calls CaseFlagForClearanceService', js: true do
        expect(CaseFlagForClearanceService).to receive(:new).with(user: press_officer, kase: assigned_case, team: press_office ).and_return(service)
        expect(service).to receive(:call).and_return(:ok)

        patch :take_case_on, params: { id: assignment.id, case_id: assigned_case.id }
      end

      context 'flag for clearance service returns ok' do
        it 'it has success message' do
          expect(CaseFlagForClearanceService).to receive(:new).with(user: press_officer, kase: assigned_case, team: press_office ).and_return(service)
          expect(service).to receive(:call).and_return(:ok)

          patch :take_case_on, params: { id: assignment.id, case_id: assigned_case.id }
          expect(assigns(:success)).to eq true
          expect(assigns(:message)).to eq I18n.t('assignments.take_case_on.success')
        end
      end

      context 'flag for clearance service returns ok' do
        it 'it has already flagged message' do
          other_user = double User, full_name: 'Joe Bloggs'
          expect(CaseFlagForClearanceService).to receive(:new).with(user: press_officer, kase: assigned_case, team: press_office ).and_return(service)
          expect(service).to receive(:other_user).and_return(other_user)
          expect(service).to receive(:call).and_return(:already_flagged)

          patch :take_case_on, params: { id: assignment.id, case_id: assigned_case.id }
          expect(assigns(:success)).to eq false
          expect(assigns(:message)).to eq I18n.t('assignments.take_case_on.already_accepted', name: other_user.full_name)
        end
      end

      context 'something else happened' do
        it 'raises an exception' do
          expect(CaseFlagForClearanceService).to receive(:new).with(user: press_officer, kase: assigned_case, team: press_office ).and_return(service)
          expect(service).to receive(:call).and_return(:foo)

          expect {
            patch :take_case_on, params: { id: assignment.id, case_id: assigned_case.id }
          }.to raise_error RuntimeError, 'Unknown error when accepting approver assignment: foo'
        end
      end
    end
  end

  describe 'GET assign_to_new_team' do

    let(:kase)              { create :assigned_case, :flagged, :dacu_disclosure, responding_team: responding_team_1 }
    let(:responding_team_1) { create :responding_team }
    let(:assignment)        { kase.responder_assignment }

    context 'as a manager' do
      before(:each)  { sign_in manager }

      context 'called without a business_group_id' do

        before(:each) { get :assign_to_new_team, params: { id: assignment.id, case_id: kase.id } }
        it 'assigns nothing to @business units' do
          expect(assigns(:business_units)).to be_nil
        end

        it 'is success' do
          expect(response).to be_success
        end

        it 'renders the template' do
          expect(response).to render_template 'assign_to_new_team'
        end
      end

      context 'called with a business group id' do

        let(:bg)     { create :business_group }
        let(:dir)    { create :directorate, business_group: bg }
        let!(:bu1)   { create :business_unit, directorate: dir }
        let!(:bu2)   { create :business_unit, directorate: dir }

        before(:each) { get :assign_to_new_team, params: { id: assignment.id, case_id: kase.id, business_group_id: bg.id } }

        it 'assigns all business units within the businss group to business_units' do
          expect(assigns(:business_units)).to match_array [ bu1, bu2 ]
        end

        it 'is success' do
          expect(response).to be_success
        end

        it 'renders the template' do
          expect(response).to render_template 'assign_to_new_team'
        end
      end
    end

    context 'as a non manager' do
      before(:each) { sign_in responder}

      it 'redirects' do
        get :assign_to_new_team, params: { id: assignment.id, case_id: kase.id }
        expect(response).to redirect_to root_path
      end

      it 'has error message in flash' do
        get :assign_to_new_team, params: { id: assignment.id, case_id: kase.id }
        expect(flash[:alert]).to eq 'You are not authorised to assign this case to another team'
      end
    end
  end

  describe 'GET edit' do

    let(:new_assignment) { instance_double Assignment }

    before(:each) { sign_in responder}

    it 'sets @assignment' do
      get :edit, params: {
        id: assignment.id,
        case_id: assignment.case.id
      }
      expect(assigns(:assignment)).to eq assignment
    end

    it 'sets @case' do
      get :edit, params: {
        id: assignment.id,
        case_id: assignment.case.id
      }
      expect(assigns(:case)).to eq assignment.case
    end

    it 'syncs case transitions tracker for user' do
      stub_find_case(assignment.case.id) do |kase|
        expect(kase).to receive(:sync_transition_tracker_for_user)
                          .with(responder)
      end

      get :edit, params: {
        id: assignment.id,
        case_id: assignment.case.id
      }
    end

    context 'authorising and routing' do

      it 'redirects to case details and displays flash notice if previously accepted' do
        sign_in responder
        assignment.accepted!

        get :edit, params: { id: assignment.id, case_id: assignment.case.id}
        expect(response).to redirect_to case_path(id: assignment.case.id, accepted_now: false )

      end

      it 'renders edit page if its not been accepted/rejected' do
        sign_in responder
        get :edit, params: { id: assignment.id, case_id: assignment.case.id}
        expect(response).to render_template(:edit)
      end

      it 'redirects to case list if assignment is not found' do
        sign_in responder

        get :edit, params: { id: 9999, case_id: assignment.case.id}

        expect(response).to redirect_to case_path(id: assignment.case.id )
        expect(flash[:notice]).to eq 'Case assignment does not exist.'
      end

    end
  end


  describe 'PATCH execute_assign_to_new_team' do

    let(:kase)              { create :assigned_case, :flagged, :dacu_disclosure, responding_team: responding_team_1 }
    let(:responding_team_1) { create :responding_team }
    let(:assignment)        { kase.responder_assignment }
    let(:bg)     { create :business_group }
    let(:dir)    { create :directorate, business_group: bg }
    let!(:bu1)   { create :business_unit, directorate: dir }
    let!(:bu2)   { create :business_unit, directorate: dir }
    let(:params) do
      ActionController::Parameters.new(
        {
          :action     => 'execute_assign_to_new_team',
          :controller => 'assignments',
          :team_id    => bu2.id.to_s,
          :id        => assignment.id.to_s,
          :case_id    => kase.id.to_s
        }
      )
    end

    context 'as a manager' do
      before(:each) { sign_in manager }

      it 'calls AssignNewTeamService' do
        service = double AssignNewTeamService
        expect(AssignNewTeamService).to receive(:new).with(manager, params).and_return(service)
        expect(service).to receive(:call)
        expect(service).to receive(:result)
        patch :execute_assign_to_new_team, params: params.to_unsafe_hash
      end

      it 'redirects if service returns ok' do
        service = double AssignNewTeamService
        expect(AssignNewTeamService).to receive(:new).with(manager, params).and_return(service)
        expect(service).to receive(:call)
        expect(service).to receive(:result).and_return(:ok)
        patch :execute_assign_to_new_team, params: params.to_unsafe_hash
        expect(flash[:notice]).to eq 'Case has been assigned to a new team'
        expect(response).to redirect_to case_path kase
      end

      it 'sets flash and returns to assign_new_team action if service fails' do
        service = double AssignNewTeamService
        expect(AssignNewTeamService).to receive(:new).with(manager, params).and_return(service)
        expect(service).to receive(:call)
        expect(service).to receive(:result).and_return(:error)
        patch :execute_assign_to_new_team, params: params.to_unsafe_hash
        expect(flash[:alert]).to eq 'Unable to assign to this team'
        expect(response).to redirect_to assign_to_new_team_case_assignment_path(kase.id, assignment.id)
      end
    end

    context 'as a non manager' do

      before(:each) do
        sign_in responder
        patch :execute_assign_to_new_team, params: params.to_unsafe_hash
      end

      it 'redirects' do
        expect(response).to redirect_to root_path
      end

      it 'has error message in flash' do
        expect(flash[:alert]).to eq 'You are not authorised to assign this case to another team'
      end
    end

  end

  describe '#assign_to_team' do
    let(:kase)              { create :timeliness }
    let(:responding_team_1) { create :responding_team }
    let(:assignment)        { kase.responder_assignment }
    let(:bg)     { create :business_group }
    let(:dir)    { create :directorate, business_group: bg }
    let!(:bu1)   { create :business_unit, directorate: dir }
    let!(:bu2)   { create :business_unit, directorate: dir }
    let(:params) do
      ActionController::Parameters.new(
        {
          :action     => 'assign_to_team',
          :controller => 'assignments',
          :team_id    => bu2.id.to_s,
          :id        => assignment.id.to_s,
          :case_id    => kase.id.to_s
        }
      )
      it 'calls CaseAssignResponderService' do
        service = double CaseAssignResponderService
        expect(CaseAssignResponderService).to receive(:new).with(manager, params).and_return(service)
        expect(service).to receive(:call)
        expect(service).to receive(:result)
        patch :assign_to_new_team, params: params.to_unsafe_hash
      end

      it 'redirects if service returns ok' do
        service = double CaseAssignResponderService
        expect(CaseAssignResponderService).to receive(:new).with(manager, params).and_return(service)
        expect(service).to receive(:call)
        expect(service).to receive(:result).and_return(:ok)
        patch :assign_to_team, params: params.to_unsafe_hash
        expect(response).to redirect_to root_open_cases_path
      end

      it 'sets flash and returns to assign_new_team action if service fails' do
        service = double CaseAssignResponderService
        expect(CaseAssignResponderService).to receive(:new).with(manager, params).and_return(service)
        expect(service).to receive(:call)
        expect(service).to receive(:result).and_return(:error)
        patch :assign_to_team, params: params.to_unsafe_hash
        expect(flash[:alert]).to eq 'Internal reviews must be flagged for clearance'
        expect(response).to redirect_to assign_to_new_team_case_assignment_path(kase.id, assignment.id)
      end
    end
  end
end

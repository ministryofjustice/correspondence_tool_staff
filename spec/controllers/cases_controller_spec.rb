require 'rails_helper'


def stub_current_case_finder_cases_with(result)
  pager = double 'Kaminari Pager', decorate: result
  cases = double 'ActiveRecord Cases', page: pager
  csf = instance_double CaseFinderService, cases: cases
  gnm = instance_double GlobalNavManager, current_cases_finder: csf
  allow(GlobalNavManager).to receive(:new).and_return gnm
  gnm
end

RSpec.describe CasesController, type: :controller do

  let(:all_cases)          { create_list(:case, 5)   }
  let(:first_case)         { all_cases.first         }
  let(:manager)            { create :manager }
  let(:responder)          { create :responder }
  let(:another_responder)  { create :responder }
  let(:responding_team)    { responder.responding_teams.first }
  let(:disclosure_specialist) { create :disclosure_specialist }
  let(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  let(:unassigned_case)    { create(:case) }
  let(:assigned_case)      { create :assigned_case,
                                    responding_team: responding_team }
  let(:accepted_case)      { create :accepted_case, responder: responder }
  let(:responded_case)     { create :responded_case, responder: responder, received_date: 5.days.ago }
  let(:case_with_response) { create :case_with_response, responder: responder }
  let(:flagged_case)       { create :assigned_case, :flagged,
                                    responding_team: responding_team,
                                    approving_team: team_dacu_disclosure }
  let(:flagged_accepted_case) { create :accepted_case, :flagged_accepted,
                                       responding_team: responding_team,
                                       approver: disclosure_specialist,
                                       responder: responder}

  let(:assigned_trigger_case)   { create :assigned_case, :flagged_accepted,
                                         approver: disclosure_specialist }
  let(:pending_dacu_clearance_case) { create :pending_dacu_clearance_case }

  before { create(:category, :foi) }

  describe '#set_cases' do
    before(:each) do
      user = create :responder
      sign_in user
      get :show, params: {id: assigned_case.id }
    end

    it 'instantiates the case' do
      expect(assigns(:case)).to eq assigned_case
    end

    it 'decorates the collection of case transitions' do
      expect(assigns(:case_transitions)).to be_an_instance_of(Draper::CollectionDecorator)
      expect(assigns(:case_transitions).map(&:class)).to eq [ CaseTransitionDecorator ]
    end
  end

  describe '#set_assignment' do
    it 'instantiates the assignments for responders' do
      sign_in responder
      get :show, params: {id: accepted_case.id}
      expect(assigns(:assignment)).to eq accepted_case.responder_assignment
    end

    it 'instantiates the assignments for approvers' do
      sign_in disclosure_specialist
      get :show, params: {id: pending_dacu_clearance_case.id}
      expect(assigns(:assignment)).to eq pending_dacu_clearance_case.approver_assignments.first
    end
  end

  context "as an anonymous user" do

    describe 'GET new' do
      it "be redirected to signin if trying to start a new case" do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'GET edit' do
      it "be redirected to signin if trying to show a specific case" do
        get :edit, params: { id: first_case }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'PATCH update' do
      it "be redirected to signin if trying to update a specific case" do
        patch :update, params: { id: first_case, case: { category_id: create(:category, :gq).id } }
        expect(response).to redirect_to(new_user_session_path)
        expect(Case.first.category.name).to eq 'Freedom of information request'
      end
    end

    describe 'GET closed_cases' do
      it "be redirected to signin if trying to update a specific case" do
        get :closed_cases
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context "as an authenticated manager" do

    before { sign_in manager }

    describe 'GET new' do
      before {
        get :new
      }

      it 'renders the new template' do
        expect(response).to render_template(:new)
      end
    end

    describe 'GET edit' do

      before do
        get :edit, params: { id: first_case }
      end

      it 'assigns @case' do
        expect(assigns(:case)).to eq(Case.first)
      end

      it 'renders the edit template' do
        expect(response).to render_template(:edit)
      end
    end

    describe 'PATCH update' do

      it 'updates the case record' do
        patch :update, params: {
          id: first_case,
          case: { category_id: create(:category, :gq).id }
        }

        expect(Case.first.category.abbreviation).to eq 'GQ'
      end

      it 'does not overwrite entries with blanks (if the blank dropdown option is selected)' do
        patch :update, params: { id: first_case, case: { category: '' } }
        expect(Case.first.category.abbreviation).to eq 'FOI'
      end
    end

    describe 'GET closed_cases' do
      it 'renders the closed cases page' do
        get :closed_cases
        expect(response).to render_template :closed_cases
      end

      it 'assigns cases returned by CaseFinderService' do
        stub_current_case_finder_cases_with(:closed_cases_result)
        get :closed_cases
        expect(assigns(:cases)).to eq :closed_cases_result
      end

      it 'passes page param to the paginator' do
        gnm = stub_current_case_finder_cases_with(:closed_cases_result)
        get :closed_cases, params: { page: 'our_page' }
        expect(gnm.current_cases_finder.cases).to have_received(:page).with('our_page')
      end
    end

    describe 'GET close' do
      it 'displays the process close page' do
        get :close, params: { id: responded_case }
        expect(response).to render_template(:close)
      end
    end

    describe 'PATCH process_closure' do
      let(:outcome) { create :outcome, :requires_refusal_reason }
      let(:refusal_reason) { create :refusal_reason }

      it "closes a case that has been responded to" do
        patch :process_closure, params: case_closure_params(responded_case)
        expect(Case.first.current_state).to eq 'closed'
        expect(Case.first.outcome_id).to eq outcome.id
        expect(Case.first.date_responded).to eq 3.days.ago.to_date
        expect(Case.first.refusal_reason_id).to eq refusal_reason.id
      end

      def case_closure_params(kase)
        date_responded = 3.days.ago
        {
          id: kase.id,
          case: {
            date_responded_dd: date_responded.day,
            date_responded_mm: date_responded.month,
            date_responded_yyyy: date_responded.year,
            outcome_name: outcome.name,
            refusal_reason_name: refusal_reason.name,
          }
        }
      end
    end

  end

  context 'as an authenticated responder' do
    before { sign_in responder }

    describe 'GET new' do
      before {
        get :new
      }

      it 'does not render the new template' do
        expect(response).not_to render_template(:new)
      end

      it 'redirects to the application root path' do
        expect(response).to redirect_to(responder_root_path)
      end
    end

  end

  # An astute reader who has persevered to this point in the file may notice
  # that the following tests are in a different structure than those above:
  # there, the top-most grouping is a context describing authentication, with
  # what action is being tested (GET new, POST create, etc) sub-grouped within
  # those contexts. This breaks up the tests for, say, GET new so that to read
  # how that action/functionality behaves becomes hard. The tests below seek to
  # remedy this by modelling how they could be grouped by functionality
  # primarily, with sub-grouping for different contexts.

  describe 'GET index' do
    let(:finder) { instance_double(CaseFinderService) }

    before do
      pager = double 'Kaminari Pager', decorate: :index_cases_result
      cases = double 'ActiveRecord Cases', page: pager
      allow(finder).to receive_message_chain :for_user,
                                             :for_action,
                                             :filter_for_params,
                                             cases: cases
      allow(CaseFinderService).to receive(:new).and_return(finder)
    end

    context "as an anonymous user" do
      it "be redirected to signin if trying to list of questions" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as an authenticated manager' do
      before { sign_in manager }

      it 'renders the index page' do
        get :index
        expect(response).to render_template :index
      end

      it 'assigns cases returned by CaseFinderService' do
        get :index
        expect(assigns(:cases)).to eq :index_cases_result
        expect(finder).to have_received(:for_user).with(manager).at_least(1).times
      end

      it 'sets @current_tab_name' do
        get :index
        expect(assigns(:current_tab_name)).to eq 'all_cases'
      end

    end

    context 'as an authenticated responder' do
      before { sign_in responder }

      it 'assigns cases returned by CaseFinderService' do
        get :index
        expect(assigns(:cases)).to eq :index_cases_result
        expect(finder).to have_received(:for_user).with(responder).at_least(1).times
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
      end

      it 'sets @current_tab_name' do
        get :index
        expect(assigns(:current_tab_name)).to eq 'all_cases'
      end

    end

    context 'as an authenticated disclosure_specialist' do

      before do
        sign_in disclosure_specialist
      end

      it 'assigns the result set from the CaseFinderService' do
        get :index
        expect(assigns(:cases)).to eq :index_cases_result
        expect(finder).to have_received(:for_user)
                            .with(disclosure_specialist)
                            .at_least(1).times
      end

      it 'sets @current_tab_name' do
        get :index
        expect(assigns(:current_tab_name)).to eq 'all_cases'
      end
    end
  end

  describe 'GET incoming_cases' do

    context "as an anonymous user" do
      it "be redirected to signin if trying to list of questions" do
        get :incoming_cases
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as an authenticated disclosure_specialist' do
      before do
        sign_in disclosure_specialist
      end

      it 'assigns the result set from the finder provided by GlobalNavManager' do
        stub_current_case_finder_cases_with(:incoming_cases_result)
        get :incoming_cases
        expect(assigns(:cases)).to eq :incoming_cases_result
      end

      it 'renders the incoming_cases template' do
        get :incoming_cases
        expect(response).to render_template(:incoming_cases)
      end

      it 'passes page param to the paginator' do
        gnm = stub_current_case_finder_cases_with(:incoming_cases_result)
        get :incoming_cases, params: { page: 'our_page' }
        expect(gnm.current_cases_finder.cases).to have_received(:page).with('our_page')
      end
    end
  end

  describe 'GET open' do

    context "as an anonymous user" do
      it "be redirected to signin if trying to list of questions" do
        get :open_cases
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as an authenticated disclosure_specialist' do
      before do
        sign_in disclosure_specialist
      end

      it 'assigns the result set from the CaseFinderService' do
        stub_current_case_finder_cases_with(:open_cases_result)
        get :open_cases
        expect(assigns(:cases)).to eq :open_cases_result
      end

      it 'passes page param to the paginator' do
        gnm = stub_current_case_finder_cases_with(:open_cases_result)
        get :open_cases, params: { page: 'our_page' }
        expect(gnm.current_cases_finder.cases).to have_received(:page).with('our_page')
      end

      it 'renders the incoming_cases template' do
        get :open_cases
        expect(response).to render_template(:index)
      end
    end
  end

  describe 'GET my_open_cases' do

    context "as an anonymous user" do
      it "be redirected to signin if trying to list of questions" do
        get :my_open_cases
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as an authenticated disclosure_specialist' do
      before do
        sign_in disclosure_specialist
      end

      it 'assigns the result set from the finder provided by GlobalNavManager' do
        stub_current_case_finder_cases_with(:my_open_cases_result)
        get :my_open_cases
        expect(assigns(:cases)).to eq :my_open_cases_result
      end

      it 'passes page param to the paginator' do
        gnm = stub_current_case_finder_cases_with(:my_open_cases_result)
        get :my_open_cases, params: { page: 'our_page' }
        expect(gnm.current_cases_finder.cases).to have_received(:page).with('our_page')
      end

      it 'renders the index template' do
        get :my_open_cases
        expect(response).to render_template(:index)
      end

      it 'sets @current_tab_name to all cases for "All open cases tab"' do
        get :my_open_cases
        expect(assigns(:current_tab_name)).to eq 'my_cases'
      end
    end
  end

  describe 'GET show' do

    it 'retrieves message_text error from the flash' do
      sign_in responder

      get :show, params: { id: accepted_case.id },
          flash:{"case_errors"=>{"message_text"=>["can't be blank"]}}

      expect(assigns(:case).errors.messages[:message_text].first)
          .to eq("can't be blank")

    end

    it 'syncs case transitions tracker for user' do
      sign_in responder

      stub_find_case(accepted_case.id) do |kase|
        expect(kase).to receive(:sync_transition_tracker_for_user)
                          .with(responder)
      end
      get :show, params: { id: accepted_case.id }
    end

    context 'viewing an unassigned case' do
      before do
        sign_in user
        get :show, params: { id: unassigned_case.id }
      end

      context 'as an anonymous user' do
        let(:user) { '' }

        it 'permitted_events == nil' do
          expect(assigns(:permitted_events)).to eq nil
        end
        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'as an authenticated manager' do
        let(:user) { create(:manager) }

        it 'permitted_events == [:add_messsage_to_case, :assign_responder, :flag_for_clearence]' do
          expect(assigns(:permitted_events)).to eq [:add_message_to_case,
                                                    :assign_responder,
                                                    :flag_for_clearance]
        end

        it 'renders the show template' do
          expect(response).to render_template(:show)
        end
      end

      context 'as a responder' do
        let(:user) { create(:responder) }

        it 'permitted_events == nil' do
          expect(assigns(:permitted_events)).to eq nil
        end

        it 'redirects to the application root path' do
          expect(response).to redirect_to(responder_root_path)
        end


      end
    end

    context 'viewing a flagged accepted case' do

      let(:user) { flagged_accepted_case.responder }

      before do
        sign_in user
        get :show, params: { id: flagged_accepted_case.id   }
      end

      it 'permitted_events == [:add_responses]' do
        expect(assigns(:permitted_events))
            .to eq [:add_message_to_case,
                    :add_response_to_flagged_case,
                    :reassign_user]
      end

      it 'renders the show page' do
        expect(response).to have_rendered(:show)
      end
    end

    context 'viewing an assigned_case' do
      before do
        sign_in user
        allow(CasesUsersTransitionsTracker).to receive(:update_tracker_for)
        get :show, params: { id: assigned_case.id }
      end

      context 'as an anonymous user' do
        let(:user) { '' }

        it 'permitted_events == nil' do
          expect(assigns(:permitted_events)).to eq nil
        end

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end

      end

      context 'as an authenticated manager' do
        let(:user) { create(:manager) }

        it 'permitted_events == []' do
          expect(assigns(:permitted_events)).to eq [:add_message_to_case, :flag_for_clearance]
        end

        it 'renders the show template' do
          expect(response).to render_template(:show)
        end

      end

      context 'as a responder of the assigned responding team' do
        let(:user)             { responder }
        let(:press_office)     { find_or_create :team_press_office }
        let(:press_officer)    { find_or_create :press_officer }
        let!(:private_officer) { find_or_create :default_private_officer }

        before do
          team_dacu_disclosure
        end

        it 'permitted_events == []' do
          expect(assigns(:permitted_events)).to be_nil
        end

        it 'renders the show template for the responder assignment' do
          responder_assignment = assigned_case.assignments.last
          create :default_press_officer
          CaseFlagForClearanceService.new(user: press_officer, kase: assigned_case, team: press_office).call
          expect(response)
              .to redirect_to(edit_case_assignment_path(
                                assigned_case,
                                responder_assignment.id))
        end

        it 'does not update the message tracker for the user' do
          expect(CasesUsersTransitionsTracker)
            .not_to have_received(:update_tracker_for)
                      .with(accepted_case, user)
        end
      end

      context 'as a responder of another responding team' do
        let(:user) { another_responder }

        it 'permitted_events == nil' do
          expect(assigns(:permitted_events)).to eq nil
        end

        it 'redirects to the application root path' do
          expect(response).to redirect_to(responder_root_path)
        end
      end
    end

    context 'viewing a case in drafting' do
      let(:accepted_case) { create(:accepted_case)   }
      before do
        sign_in user
        get :show, params: { id: accepted_case.id   }
      end

      context 'as an anonymous user' do
        let(:user) { '' }

        it 'permitted_events == nil' do
          expect(assigns(:permitted_events)).to eq nil
        end

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'as an authenticated manager' do
        let(:user) { create(:manager) }

        it 'permitted_events == []' do
          expect(assigns(:permitted_events)).to eq [:add_message_to_case, :flag_for_clearance]
        end

        it 'renders the show page' do
          expect(response).to have_rendered(:show)
        end
      end

      context 'as the assigned responder' do
        context 'unflagged case' do
          let(:user) { accepted_case.responder }

          it 'permitted_events == [:add_responses]' do
            expect(assigns(:permitted_events))
                .to eq [:add_message_to_case,
                        :add_responses,
                        :reassign_user]
            nil
          end

          it 'renders the show page' do
            expect(response).to have_rendered(:show)
          end
        end
      end

      context 'as another responder' do
        let(:user) { create(:responder) }

        it 'permitted_events == []' do
          expect(assigns(:permitted_events)).to be_nil
        end

        it 'redirects to the application root path' do
          expect(response).to redirect_to(responder_root_path)
        end
      end
    end

    context 'viewing a case_with_response' do
      before do
        sign_in user
        get :show, params: { id: case_with_response.id }
      end

      context 'as an anonymous user' do
        let(:user) { '' }

        it 'permitted_events == nil' do
          expect(assigns(:permitted_events)).to eq nil
        end

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'as an authenticated manager' do
        let(:user) { create(:manager) }

        it 'permitted_events == []' do
          expect(assigns(:permitted_events)).to eq [:add_message_to_case, :flag_for_clearance]
        end

        it 'renders the show page' do
          expect(response).to have_rendered(:show)
        end
      end

      context 'as the assigned responder' do
        let(:user) { case_with_response.responder }

        it 'permitted_events == [:add_responses, :respond]' do
          expect(assigns(:permitted_events)).to match_array [
                                                  :add_message_to_case,
                                                  :add_responses,
                                                  :respond,
                                                  :remove_response,
                                                  :remove_last_response
                                                ]
        end

        it 'renders the show page' do
          expect(response).to have_rendered(:show)
        end
      end

      context 'as another responder' do
        let(:user) { create(:responder) }

        it 'permitted_events == []' do
          expect(assigns(:permitted_events)).to be_nil
        end

        it 'redirects to the application root path' do
          expect(response).to redirect_to(responder_root_path)
        end
      end
    end

    context 'viewing a responded_case' do
      let(:responded_case) { create(:responded_case, received_date: 5.days.ago )   }
      before do
        sign_in user
        get :show, params: { id: responded_case.id   }
      end

      context 'as an anonymous user' do
        let(:user) { '' }

        it 'permitted_events == nil' do
          expect(assigns(:permitted_events)).to eq nil
        end

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'as an authenticated manager' do
        let(:user) { create(:manager) }

        it 'permitted_events == [:close]' do
          expect(assigns(:permitted_events)).to eq [:add_message_to_case, :close]
        end

        it 'renders the show page' do
          expect(response).to have_rendered(:show)
        end
      end

      context 'as the previously assigned responder' do
        let(:user) { responder }

        it 'permitted_events == []' do
          expect(assigns(:permitted_events)).to be_nil
        end

        it 'redirects to the application root path' do
          expect(response).to redirect_to(responder_root_path)
        end
      end

      context 'as another responder' do
        let(:user) { create(:responder) }

        it 'permitted_events == []' do
          expect(assigns(:permitted_events)).to be_nil
        end

        it 'redirects to the application root path' do
          expect(response).to redirect_to(responder_root_path)
        end
      end
    end

  end

  describe 'POST create' do
    context 'as an authenticated responder' do
      before { sign_in responder }

      let(:params) do
        {
          case: {
            requester_type: 'member_of_the_public',
            name: 'A. Member of Public',
            postal_address: '102 Petty France',
            email: 'member@public.com',
            subject: 'Responders cannot create cases',
            message: 'I am a responder attempting to create a case',
            received_date_dd: Time.zone.today.day.to_s,
            received_date_mm: Time.zone.today.month.to_s,
            received_date_yyyy: Time.zone.today.year.to_s
          }
        }
      end

      subject { post :create, params: params }

      it 'does not create a new case' do
        expect{ subject }.not_to change { Case.count }
      end

      it 'redirects to the application root path' do
        expect(subject).to redirect_to(responder_root_path)
      end
    end

    context "as an authenticated manager" do
      before do
        sign_in manager
        find_or_create :team_dacu
        find_or_create :team_dacu_disclosure
      end

      context 'with valid params' do
        let(:params) do
          {
            case: {
              requester_type: 'member_of_the_public',
              name: 'A. Member of Public',
              postal_address: '102 Petty France',
              email: 'member@public.com',
              subject: 'FOI request from controller spec',
              message: 'FOI about prisons and probation',
              received_date_dd: Time.zone.today.day.to_s,
              received_date_mm: Time.zone.today.month.to_s,
              received_date_yyyy: Time.zone.today.year.to_s,
              delivery_method: :sent_by_email,
              flag_for_disclosure_specialists: false,
              uploaded_request_files: ['uploads/71/request/request.pdf'],
            }
          }
        end

        let(:created_case) { Case.first }

        it 'makes a DB entry' do
          expect { post :create, params: params }.
            to change { Case.count }.by 1
        end

        it 'uses the params provided' do
          post :create, params: params

          expect(created_case.requester_type).to eq 'member_of_the_public'
          expect(created_case.name).to eq 'A. Member of Public'
          expect(created_case.postal_address).to eq '102 Petty France'
          expect(created_case.email).to eq 'member@public.com'
          expect(created_case.subject).to eq 'FOI request from controller spec'
          expect(created_case.message).to eq 'FOI about prisons and probation'
          expect(created_case.received_date).to eq Time.zone.today
        end

        describe 'flag_for_clearance' do
          let!(:service) do
            double(CaseFlagForClearanceService, call: true).tap do |svc|
              allow(CaseFlagForClearanceService).to receive(:new).and_return(svc)
            end
          end

          it 'does not flag for clearance if parameter is not set' do
            params[:case].delete(:flag_for_disclosure_specialists)
            expect { post :create, params: params }
              .not_to change { Case.count }
            expect(service).not_to have_received(:call)
          end

          it "returns an error message if parameter is not set" do
            params[:case].delete(:flag_for_disclosure_specialists)
            post :create, params: params
            expect(assigns(:case).errors).to have_key(:flag_for_disclosure_specialists)
            expect(response).to have_rendered(:new)
          end

          it "flags the case for clearance if parameter is true" do
            params[:case][:flag_for_disclosure_specialists] = 'yes'
            post :create, params: params
            expect(service).to have_received(:call)
          end

          it "does not flag the case for clearance if parameter is false" do
            params[:case][:flag_for_disclosure_specialists] = false
            post :create, params: params
            expect(service).not_to have_received(:call)
          end
        end
      end
    end
  end

  describe 'GET new_response_upload' do
    let(:kase) { create(:accepted_case, responder: responder) }

    context 'as an anonymous user' do
      describe 'GET new_response_upload' do
        it 'redirects to signin' do
          get :new_response_upload, params: { id: kase }
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context "as a responder who isn't assigned to the case" do
      let(:unassigned_responder) { create(:responder) }

      before { sign_in unassigned_responder }

      it 'redirects to case detail page' do
        get :new_response_upload, params: { id: kase }
        expect(response).to redirect_to(case_path(kase))
      end
    end

    context 'as the assigned responder' do
      before { sign_in responder }

      it 'assigns @case' do
        get :new_response_upload, params: { id: kase, action: 'upload' }
        expect(assigns(:case)).to eq(Case.first)
      end

      it 'assigns NextStepInfo' do
        nsi = double NextStepInfo
        expect(NextStepInfo).to receive(:new)
                                  .with(kase, 'upload', responder)
                                  .and_return(nsi)

        get :new_response_upload, params: { id: kase, action: 'upload' }
        expect(assigns(:next_step_info)).to eq nsi
      end

      it 'renders the new_response_upload view' do
        get :new_response_upload, params: { id: kase, action: 'upload'  }
        expect(response).to have_rendered(:new_response_upload)
      end
    end


    context 'as an authenticated manager' do
      before { sign_in manager }

      it 'redirects to case detail page' do
        get :new_response_upload, params: { id: kase }
        expect(response).to redirect_to(case_path(kase))
      end
    end

  end

  describe 'POST upload responses' do
    let(:kase) { create(:accepted_case, responder: responder) }
    let(:uploads_key) { "uploads/#{kase.id}/responses/#{Faker::Internet.slug}.jpg" }
    let(:params) do
      {
        id:             kase,
        type:           'response',
        uploaded_files: [uploads_key]
      }
    end

    def do_upload_responses
      post :upload_responses, params: params
    end


    context 'as an anonymous user' do

      it 'does not call ResponseUploaderService' do
        expect(ResponseUploaderService).not_to receive(:new)
      end

      it 'redirects to signin' do
        do_upload_responses
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "as a responder who isn't assigned to the case" do
      let(:unassigned_responder) { create(:responder) }

      before { sign_in unassigned_responder }

      it 'does not call ResponseUploaderService' do
        expect(ResponseUploaderService).not_to receive(:new)
      end

      it 'redirects to case detail page' do
        do_upload_responses
        expect(response).to redirect_to(case_path(kase))
      end
    end

    # TODO: ensure removed files are removed from params list  ???


    #     context 'files removed from dropzone upload' do
    #       let(:leftover_files) do
    #         [instance_double(Aws::S3::Object, delete: nil)]
    #       end
    #
    #       it 'removes any files left behind in uploads' do
    #         do_upload_responses
    #         leftover_files.each do |object|
    #           expect(object).to have_received(:delete)
    #         end
    #       end
    #     end

    context 'as the assigned responder' do
      before { sign_in responder }

      let(:uploader) { double ResponseUploaderService }
      let(:expected_params) { ActionController::Parameters.new({"type"=>"response", "uploaded_files"=>[uploads_key], "id"=>kase.id.to_s, "controller"=>"cases", "action"=>"upload_responses"}) }
      let(:response_uploader) { double ResponseUploaderService, upload!: nil, result: :ok }
      let(:flash) { MockFlash.new(action_params: 'upload')}

      it 'calls ResponseUploaderService' do
        allow_any_instance_of(CasesController).to receive(:flash).and_return(flash)
        expect(ResponseUploaderService).to receive(:new).with(kase.decorate, responder, expected_params, 'upload').and_return(response_uploader)
        do_upload_responses
      end

      it 'redirects to the case detail page' do
        allow_any_instance_of(CasesController).to receive(:flash).and_return(flash)
        expect(ResponseUploaderService).to receive(:new).and_return(response_uploader)
        do_upload_responses
        expect(response).to redirect_to(case_path(kase))
      end

      context 'no files specified' do
        before do
          allow_any_instance_of(CasesController).to receive(:flash).and_return(flash)
          expect(ResponseUploaderService).to receive(:new).and_return(response_uploader)
          expect(response_uploader).to receive(:result).and_return(:blank)
        end

        it 're-renders the page' do
          do_upload_responses
          expect(response).to have_rendered(:new_response_upload)
        end

        it 'keeps the action_params flash' do
          do_upload_responses
          expect(flash.kept).to include :action_params
        end
      end

      context 'there is an upload error' do
        before do
          allow_any_instance_of(CasesController).to receive(:flash).and_return(flash)
          expect(ResponseUploaderService).to receive(:new).and_return(response_uploader)
          expect(response_uploader).to receive(:result).and_return(:error)
        end

        it 're-renders the page if there is an upload error' do
          do_upload_responses
          expect(response).to have_rendered(:new_response_upload)
        end

        it 'keeps the action_params flash' do
          do_upload_responses
          expect(flash.kept).to include :action_params
        end
      end
    end
  end

  describe 'GET respond' do

    let(:responder)            { create(:responder)                              }
    let(:another_responder)    { create(:responder)                              }

    context 'as an anonymous user' do
      it 'redirects to sign_in' do
        expect(get :respond, params: { id: case_with_response.id }).
          to redirect_to(new_user_session_path)
      end
    end

    context 'as an authenticated manager' do

      before { sign_in manager }

      it 'redirects to the application root' do
        expect(get :respond, params: { id: case_with_response.id }).
            to redirect_to(manager_root_path)
      end
    end

    context 'as the assigned responder' do

      before { sign_in responder }

      it 'does not transition current_state' do
        expect(case_with_response.current_state).to eq 'awaiting_dispatch'
        get :respond, params: { id: case_with_response.id }
        expect(case_with_response.current_state).to eq 'awaiting_dispatch'
      end

      it 'renders the respond template' do
        expect(get :respond, params: { id: case_with_response.id }).
            to render_template(:respond)
      end
    end

    context 'as another responder' do

      before { sign_in another_responder }

      it 'redirects to the application root' do
        expect(get :respond, params: { id: case_with_response.id }).
              to redirect_to(responder_root_path)
      end
    end
  end

  describe 'PATCH confirm_respond' do
    let(:another_responder)  { create(:responder) }

    context 'as an anonymous user' do
      it 'redirects to sign_in' do
        expect(patch :confirm_respond, params: { id: case_with_response.id }).
          to redirect_to(new_user_session_path)
      end

      it 'does not transition current_state' do
        expect(case_with_response.current_state).to eq 'awaiting_dispatch'
        patch :confirm_respond, params: { id: case_with_response.id }
        expect(case_with_response.current_state).to eq 'awaiting_dispatch'
      end
    end

    context 'as an authenticated manager' do

      before { sign_in manager }

      it 'redirects to the application root' do
        expect(patch :confirm_respond, params: { id: case_with_response.id }).
            to redirect_to(manager_root_path)
      end

      it 'does not transition current_state' do
        expect(case_with_response.current_state).to eq 'awaiting_dispatch'
        patch :confirm_respond, params: { id: case_with_response.id }
        expect(case_with_response.current_state).to eq 'awaiting_dispatch'
      end
    end

    context 'as the assigned responder' do

      before { sign_in responder }

      it 'transitions current_state to "responded"' do
        stub_find_case(case_with_response.id) do |kase|
          expect(kase).to receive(:respond).with(responder)
        end
        patch :confirm_respond, params: { id: case_with_response }
      end

      it 'redirects to the case list view' do
        expect(patch :confirm_respond, params: { id: case_with_response.id }).
            to redirect_to(case_path(case_with_response))
      end
    end

    context 'as another responder' do

      before { sign_in another_responder }

      it 'redirects to the application root' do
        expect(patch :confirm_respond, params: { id: case_with_response.id }).
              to redirect_to(responder_root_path)
      end

      it 'does not transition current_state' do
        expect(case_with_response.current_state).to eq 'awaiting_dispatch'
        patch :confirm_respond, params: { id: case_with_response.id }
        expect(case_with_response.current_state).to eq 'awaiting_dispatch'
      end
    end
  end

  describe 'PATCH unflag_for_clearance' do
    let!(:service) do
      double(CaseUnflagForClearanceService, call: true).tap do |svc|
        allow(CaseUnflagForClearanceService).to receive(:new).and_return(svc)
      end
    end

    let(:flagged_case_decorated) do
      flagged_case.decorate.tap do |decorated|
        allow(flagged_case).to receive(:decorate).and_return(decorated)
      end
    end

    let(:params) { { id: flagged_case.id } }

    context 'as an anonymous user' do
      it 'redirects to sign_in' do
        expect(patch :unflag_for_clearance, params: params)
          .to redirect_to(new_user_session_path)
      end

      it 'does not call the service' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(CaseUnflagForClearanceService).not_to have_received(:new)
      end

      it 'returns an error' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(response).to have_http_status 401
      end
    end

    context 'as an authenticated responder' do
      before do
        sign_in responder
      end

      it 'does not call the service' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(CaseUnflagForClearanceService).not_to have_received(:new)
      end

      it 'redirects to the application root path' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(response.body)
          .to include 'Turbolinks.visit("http://test.host/", {"action":"replace"})'
      end
    end

    context 'as an authenticated manager' do
      before do
        sign_in manager
      end

      it 'instantiates and calls the service' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(CaseUnflagForClearanceService)
          .to have_received(:new).with(user: manager,
                                       kase: flagged_case_decorated,
                                       team: BusinessUnit.dacu_disclosure)
        expect(service).to have_received(:call)
      end

      it 'renders the view' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(response).to have_rendered(:unflag_for_clearance)
      end

      it 'returns a success code' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(response).to have_http_status 200
      end
    end

    context 'as an authenticated disclosure_specialist' do
      before do
        sign_in disclosure_specialist
      end

      it 'instantiates and calls the service' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(CaseUnflagForClearanceService)
          .to have_received(:new).with(user: disclosure_specialist,
                                       kase: flagged_case_decorated,
                                       team: BusinessUnit.dacu_disclosure)
        expect(service).to have_received(:call)
      end

      it 'renders the view' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(response).to have_rendered(:unflag_for_clearance)
      end

      it 'returns success' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(response).to have_http_status 200
        expect(response).to have_rendered(:unflag_for_clearance)
      end
    end
  end

  describe 'PATCH flag_for_clearance' do
    let!(:service) do
      double(CaseFlagForClearanceService, call: true).tap do |svc|
        allow(CaseFlagForClearanceService).to receive(:new).and_return(svc)
      end
    end

    let(:unflagged_case_decorated) do
      assigned_case.decorate.tap do |decorated|
        allow(assigned_case).to receive(:decorate).and_return(decorated)
      end
    end

    let(:params) { { id: assigned_case.id } }

    context 'as an anonymous user' do
      it 'redirects to sign_in' do
        expect(patch :flag_for_clearance, params: params)
          .to redirect_to(new_user_session_path)
      end

      it 'does not call the service' do
        patch :flag_for_clearance, params: params, xhr: true
        expect(CaseFlagForClearanceService).not_to have_received(:new)
      end

      it 'returns an error' do
        patch :flag_for_clearance, params: params, xhr: true
        expect(response).to have_http_status 401
      end
    end

    context 'as an authenticated responder' do
      before do
        sign_in responder
      end

      it 'does not call the service' do
        patch :flag_for_clearance, params: params, xhr: true
        expect(CaseFlagForClearanceService).not_to have_received(:new)
      end

      it 'redirects to the application root path' do
        patch :flag_for_clearance, params: params, xhr: true
        expect(response.body)
          .to include 'Turbolinks.visit("http://test.host/", {"action":"replace"})'
      end
    end

    context 'as an authenticated manager' do
      let!(:dacu_disclosure) { find_or_create :team_dacu_disclosure }
      before do
        sign_in manager
      end

      it 'instantiates and calls the service' do
        patch :flag_for_clearance, params: params, xhr: true
        expect(CaseFlagForClearanceService)
          .to have_received(:new).with(user: manager,
                                       kase: unflagged_case_decorated,
                                       team: BusinessUnit.dacu_disclosure)
        expect(service).to have_received(:call)
      end

      it 'renders the view' do
        patch :flag_for_clearance, params: params, xhr: true
        expect(response).to have_rendered(:flag_for_clearance)
      end

      it 'returns a success code' do
        patch :flag_for_clearance, params: params, xhr: true
        expect(response).to have_http_status 200
      end
    end

    context 'as an authenticated disclosure_specialist' do
      before do
        sign_in disclosure_specialist
      end

      it 'instantiates and calls the service' do
        patch :flag_for_clearance, params: params, xhr: true
        expect(CaseFlagForClearanceService)
          .to have_received(:new).with(user: disclosure_specialist,
                                       kase: unflagged_case_decorated,
                                       team: BusinessUnit.dacu_disclosure)
        expect(service).to have_received(:call)
      end

      it 'renders the view' do
        patch :flag_for_clearance, params: params, xhr: true
        expect(response).to have_rendered(:flag_for_clearance)
      end

      it 'returns success' do
        patch :flag_for_clearance, params: params, xhr: true
        expect(response).to have_http_status 200
      end
    end
  end

  describe 'GET approve_response' do
    context "as an anonymous user" do
      it "be redirected to signin if trying to approve a case" do
        get :approve_response, params: { id: assigned_trigger_case.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as an authenticated manager' do
      before { sign_in manager }

      it 'redirects to the root' do
        get :approve_response, params: { id: assigned_trigger_case.id }
        expect(response).to redirect_to(root_path)
      end
    end

    context 'as an authenticated responder' do
      before { sign_in responder }

      it 'redirects to the root' do
        get :approve_response, params: { id: assigned_trigger_case.id }
        expect(response).to redirect_to(root_path)
      end
    end

    context 'as an authenticated disclosure_specialist' do
      before do
        sign_in pending_dacu_clearance_case.approvers.first
      end

      it 'renders the view' do
        get :approve_response, params: { id: pending_dacu_clearance_case.id }
        expect(response).to have_rendered(:approve_response)
      end

      it 'requires the correct permission' do
        expect {
          get :approve_response, params: { id: pending_dacu_clearance_case.id }
        } .to require_permission(:can_approve_or_escalate_case?)
                .with_args(pending_dacu_clearance_case.approvers.first,
                           pending_dacu_clearance_case)
      end

      it 'gets the next step info' do
        allow(NextStepInfo).to receive(:new).and_return(:new_next_step_info)
        get :approve_response, params: { id: pending_dacu_clearance_case.id }
        expect(NextStepInfo).to have_received(:new)
                                  .with(pending_dacu_clearance_case,
                                        'approve',
                                        pending_dacu_clearance_case.approvers.first)
        expect(assigns[:next_step_info]).to eq :new_next_step_info
      end
    end
  end

  describe 'GET search' do
    before(:each) do
      sign_in responder
    end

    it 'renders the index template' do
      get :search
      expect(response).to render_template(:index)
    end

    it 'finds a case by number' do
      get :search, params: { query: assigned_case.number }
      expect(assigns[:cases]).to eq [assigned_case]
    end

    it 'ignores leading or trailing whitespace' do
      get :search, params: { query: " #{assigned_case.number} " }
      expect(assigns[:cases]).to eq [assigned_case]
    end

    it 'passes page param to the paginator' do
      paged_cases = double('Paged Cases', decorate: [])
      cases = double('Cases', page: paged_cases, empty?: true)
      allow(Case).to receive(:search).and_return(cases)
      get :search, params: { query: assigned_case.number, page: 'our_pages' }
      expect(cases).to have_received(:page).with('our_pages')
    end
  end

end

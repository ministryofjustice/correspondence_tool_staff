require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')


def stub_current_case_finder_cases_with(result)
  pager = double 'Kaminari Pager', decorate: result
  cases_by_deadline = double 'ActiveRecord Cases', page: pager
  cases = double 'ActiveRecord Cases', by_deadline: cases_by_deadline
  page = instance_double GlobalNavManager::Page, cases: cases
  gnm = instance_double GlobalNavManager, current_page_or_tab: page
  allow(GlobalNavManager).to receive(:new).and_return gnm
  gnm
end

RSpec.describe CasesController, type: :controller do

  let(:all_cases)             { create_list(:case, 5)   }
  let(:first_case)            { all_cases.first         }
  let(:manager)               { create :manager }
  let(:responder)             { create :responder }
  let(:another_responder)     { create :responder }
  let(:responding_team)       { responder.responding_teams.first }
  let(:co_responder)          { create :responder,
                                       responding_teams: [responding_team] }
  let(:disclosure_specialist) { create :disclosure_specialist }
  let(:team_dacu_disclosure)  { find_or_create :team_dacu_disclosure }
  let(:approver_responder)    { create :approver_responder,
                                        approving_team: team_dacu_disclosure }
  let(:unassigned_case)       { create(:case) }
  let(:assigned_case)         { create :assigned_case,
                                        responding_team: responding_team }
  let(:accepted_case)         { create :accepted_case, responder: responder }
  let(:responded_case)        { create :responded_case, responder: responder, received_date: 5.days.ago }
  let(:case_with_response)    { create :case_with_response, responder: responder }
  let(:flagged_case)          { create :assigned_case, :flagged,
                                        responding_team: responding_team,
                                        approving_team: team_dacu_disclosure }
  let(:flagged_accepted_case) { create :accepted_case, :flagged_accepted,
                                       responding_team: responding_team,
                                       approver: disclosure_specialist,
                                       responder: responder}

  let(:assigned_trigger_case)               { create :assigned_case, :flagged_accepted,
                                                      approver: disclosure_specialist }
  let(:pending_dacu_clearance_case)         { create :pending_dacu_clearance_case }
  let(:case_accepted_by_approver_responder) { create :accepted_case,
                                                     :flagged_accepted,
                                                     approver:  approver_responder,
                                                     responder: approver_responder }
  let(:case_only_accepted_for_approving) { create :accepted_case,
                                                  :flagged_accepted,
                                                  approver:  approver_responder,
                                                  responder: responder }


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

  describe '#set_assignments' do
    context 'current user is only in responder team' do
      it 'instantiates the assignments for responders' do
        sign_in responder
        get :show, params: {id: accepted_case.id}
        expect(assigns(:assignments)).to eq [ accepted_case.responder_assignment ]
      end
    end

    context 'current user is another responder on same team' do
      let(:kase) { accepted_case }

      it 'instantiates responding assignment' do
        sign_in co_responder
        get :show, params: {id: kase.id}
        expect(assigns(:assignments)).to eq [ kase.responder_assignment ]
      end
    end

    context 'current_user is in both responder and approver team' do
      it 'instantiates both the assignments for responders and approvers' do
        kase = case_accepted_by_approver_responder
        sign_in approver_responder
        get :show, params: {id: kase.id}
        expect(assigns(:assignments)).to eq [ kase.responder_assignment, kase.approver_assignments.first ]
      end
    end

    context 'current user is responder on a different team' do
      let(:kase) { case_only_accepted_for_approving }

      it 'does not instantiate responding assignment' do
        sign_in approver_responder
        get :show, params: {id: kase.id}
        expect(assigns(:assignments)).to eq [ kase.approver_assignments.first ]
      end
    end

    it 'instantiates the assignments for approvers' do
      sign_in disclosure_specialist
      get :show, params: {id: pending_dacu_clearance_case.id}
      expect(assigns(:assignments)).to eq [ pending_dacu_clearance_case.approver_assignments.first ]
    end
  end

  context "as an anonymous user" do

    describe 'GET closed_cases' do
      it "be redirected to signin if trying to update a specific case" do
        get :closed_cases
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context "as an authenticated manager" do

    before { sign_in manager }

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
        expect(gnm.current_page_or_tab.cases.by_deadline)
          .to have_received(:page).with('our_page')
      end
    end

    describe 'GET close' do
      it 'displays the process close page' do
        get :close, params: { id: responded_case }
        expect(response).to render_template(:close)
      end
    end

    describe 'PATCH process_closure' do
      let(:outcome)     { find_or_create :outcome, :requires_refusal_reason }
      let(:info_held)   { find_or_create :info_status, :held }

      it 'authorizes using can_close_case?' do
        expect{
          patch :process_closure, params: case_closure_params(responded_case)
        }.to require_permission(:can_close_case?)
               .with_args(manager, responded_case)
      end

      it "closes a case that has been responded to" do
        patch :process_closure, params: case_closure_params(responded_case)
        expect(Case::Base.first.current_state).to eq 'closed'
        expect(Case::Base.first.outcome_id).to eq outcome.id
        expect(Case::Base.first.date_responded).to eq 3.days.ago.to_date
      end

      def case_closure_params(kase)
        date_responded = 3.days.ago
        {
          id: kase.id,
          case_foi: {
            date_responded_dd: date_responded.day,
            date_responded_mm: date_responded.month,
            date_responded_yyyy: date_responded.year,
            info_held_status_abbreviation: info_held.abbreviation,
            outcome_name: outcome.name,
            # refusal_reason_name: refusal_reason.name,
          }
        }
      end

      context 'FOI internal review' do
        let(:appeal_outcome)    { find_or_create :appeal_outcome, :upheld }
        let(:info_held)         { find_or_create :info_status, :not_held }
        let(:internal_review)   { create :responded_compliance_review }

        it "closes a case that has been responded to" do
          patch :process_closure, params: case_closure_params(internal_review)
          expect(Case::Base.first.current_state).to eq 'closed'
          expect(Case::Base.first.appeal_outcome_id).to eq appeal_outcome.id
          expect(Case::Base.first.date_responded).to eq 3.days.ago.to_date
        end

        def case_closure_params(internal_review)
          date_responded = 3.days.ago
          {
            id: internal_review.id,
            case_foi: {
              date_responded_dd: date_responded.day,
              date_responded_mm: date_responded.month,
              date_responded_yyyy: date_responded.year,
              info_held_status_abbreviation: info_held.abbreviation,
              appeal_outcome_name: appeal_outcome.name
            }
          }
        end
      end

      context 'SAR' do
        let(:responder)   { create :responder }
        let(:sar)         { create :accepted_sar, responder: responder }

        before(:all) do
          CaseClosure::MetadataSeeder.seed!
        end

        after(:all) do
          CaseClosure::MetadataSeeder.unseed!
        end

        it "closes a case that has been responded to" do
          sign_in responder
          patch :process_closure, params: sar_closure_params(sar)
          expect(Case::SAR.first.current_state).to eq 'closed'
          expect(Case::SAR.first.refusal_reason_id).to eq CaseClosure::RefusalReason.tmm.id
          expect(Case::SAR.first.date_responded).to eq 3.days.ago.to_date
        end

        def sar_closure_params(sar)
          date_responded = 3.days.ago
          {
            id: sar.id,
            case_sar: {
              date_responded_dd: date_responded.day,
              date_responded_mm: date_responded.month,
              date_responded_yyyy: date_responded.year,
              missing_info: 'yes'
            }
          }
        end
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
    let(:decorate_result) { double 'decorated_result' }
    let(:pager) { double 'Kaminari Pager', decorate: decorate_result }
    let(:cases) { double 'ActiveRecord Cases', page: pager }
    let(:finder) { instance_double(CaseFinderService, scope: cases) }

    before do
      allow(CaseFinderService).to receive(:new).and_return(finder)
      allow(finder).to receive(:for_user).and_return(finder)
      allow(finder).to receive(:for_params).and_return(finder)
    end

    context "as an anonymous user" do
      it "be redirected to signin if trying to list of questions" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as an authenticated user' do
      before { sign_in manager }

      it 'renders the index page' do
        get :index
        expect(response).to render_template :index
      end

      it 'assigns cases returned by CaseFinderService' do
        get :index
        expect(CaseFinderService).to have_received(:new).with(manager)
        expect(assigns(:cases)).to eq decorate_result
      end

      it 'sets @current_tab_name' do
        get :index
        expect(assigns(:current_tab_name)).to eq 'all_cases'
      end

      it 'sets @can_add_case to true' do
        get :index
        expect(assigns(:can_add_case)).to eq true
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
        expect(gnm.current_page_or_tab.cases.by_deadline)
          .to have_received(:page).with('our_page')
      end
    end
  end

  describe 'GET open' do

    context "as an anonymous user" do
      it "be redirected to signin if trying to list of questions" do
        get :open_cases, params: {tab: 'in_time'}
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as an authenticated disclosure_specialist' do
      before do
        sign_in disclosure_specialist
      end

      it 'assigns the result set from the CaseFinderService' do
        stub_current_case_finder_cases_with(:open_cases_result)
        get :open_cases, params: {tab: 'in_time'}
        expect(assigns(:cases)).to eq :open_cases_result
      end

      it 'passes page param to the paginator' do
        gnm = stub_current_case_finder_cases_with(:open_cases_result)
        get :open_cases, params: { page: 'our_page', tab: 'in_time' }
        expect(gnm.current_page_or_tab.cases.by_deadline)
          .to have_received(:page).with('our_page')
      end

      it 'renders the index template' do
        get :open_cases, params: {tab: 'in_time'}
        expect(response).to render_template(:index)
      end
    end
  end

  describe 'GET my_open_cases' do

    context "as an anonymous user" do
      it "be redirected to signin if trying to list of questions" do
        get :my_open_cases, params: {tab: 'in_time'}
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as an authenticated disclosure_specialist' do
      before do
        sign_in disclosure_specialist
      end

      it 'assigns the result set from the finder provided by GlobalNavManager' do
        stub_current_case_finder_cases_with(:my_open_cases_result)
        get :my_open_cases, params: { tab: 'in_time' }
        expect(assigns(:cases)).to eq :my_open_cases_result
      end

      it 'passes page param to the paginator' do
        gnm = stub_current_case_finder_cases_with(:my_open_cases_result)
        get :my_open_cases, params: { page: 'our_page', tab: 'in_time' }
        expect(gnm.current_page_or_tab.cases.by_deadline)
          .to have_received(:page).with('our_page')
      end

      it 'renders the index template' do
        stub_current_case_finder_cases_with(:my_open_cases_result)
        get :my_open_cases, params: { tab: 'in_time' }
        expect(response).to render_template(:index)
      end

      it 'sets @current_tab_name to all cases for "All open cases tab"' do
        stub_current_case_finder_cases_with(:my_open_cases_result)
        get :my_open_cases, params: { tab: 'in_time' }
        expect(assigns(:current_tab_name)).to eq 'my_cases'
      end
    end
  end

  describe 'GET show' do

    it 'retrieves message_text error from the flash' do
      sign_in responder

      get :show, params: { id: accepted_case.id },
          flash:{"case_errors"=>{:message_text => ["can't be blank"]}}

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

        it { should have_nil_permitted_events }

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'as an authenticated manager' do
        let(:user) { create(:manager) }

        it { should have_permitted_events_including :add_message_to_case,
                                                    :assign_responder,
                                                    :destroy_case,
                                                    :edit_case,
                                                    :flag_for_clearance }

        it 'renders the show template' do
          expect(response).to render_template(:show)
        end
      end

      context 'as a responder' do
        let(:user) { create(:responder) }

        it { should have_permitted_events_including :link_a_case }

        it 'renders case details page' do
          expect(response).to render_template :show
        end


      end
    end

    context 'viewing a flagged accepted case' do

      let(:user) { flagged_accepted_case.responder }

      before do
        sign_in user
        get :show, params: { id: flagged_accepted_case.id   }
      end

      it {should have_permitted_events_including :add_message_to_case,
                                                 :add_response_to_flagged_case,
                                                 :reassign_user }

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

        it { should have_nil_permitted_events }

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end

      end

      context 'as an authenticated manager' do
        let(:user) { create(:manager) }

        it 'permitted_events == []' do
          expect(assigns(:filtered_permitted_events)).to eq [:add_message_to_case, :assign_to_new_team, :destroy_case, :edit_case, :flag_for_clearance]
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

        it { should have_nil_permitted_events }

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

        it 'permitted_events to containe add_message_to_case only' do
          expect(assigns(:filtered_permitted_events)).to be_empty
        end

        it 'renders case details page' do
          expect(response).to render_template :show
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

        it { should have_nil_permitted_events }

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'as an authenticated manager' do
        let(:user) { create(:manager) }

        it { should have_permitted_events_including :add_message_to_case,
                                                    :assign_to_new_team,
                                                    :destroy_case,
                                                    :edit_case,
                                                    :flag_for_clearance }

        it 'renders the show page' do
          expect(response).to have_rendered(:show)
        end
      end

      context 'as the assigned responder' do
        context 'unflagged case' do
          let(:user) { accepted_case.responder }

          it { should have_permitted_events_including :add_message_to_case,
                                                      :add_responses,
                                                      :reassign_user }

          it 'renders the show page' do
            expect(response).to have_rendered(:show)
          end
        end
      end

      context 'as another responder' do
        let(:user) { create(:responder) }

        it 'filtered permitted_events to be empty' do
          expect(assigns(:filtered_permitted_events)).to be_empty
        end

        it 'renders case details page' do
          expect(response).to render_template :show
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

        it { should have_nil_permitted_events }

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'as an authenticated manager' do
        let(:user) { create(:manager) }

        it { should have_permitted_events_including :add_message_to_case,
                                                    :destroy_case,
                                                    :edit_case,
                                                    :flag_for_clearance }

        it 'renders the show page' do
          expect(response).to have_rendered(:show)
        end
      end

      context 'as the assigned responder' do
        let(:user) { case_with_response.responder }

        it { should have_permitted_events_including :add_message_to_case,
                                                         :add_responses,
                                                         :respond,
                                                         :remove_response }

        it 'renders the show page' do
          expect(response).to have_rendered(:show)
        end
      end

      context 'as another responder' do
        let(:user) { create(:responder) }

        it 'filtered permitted_events to be empty' do
          expect(assigns(:filtered_permitted_events)).to be_empty
        end

        it 'renders case details page' do
          expect(response).to render_template :show
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

        it { should have_nil_permitted_events }

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'as an authenticated manager' do
        let(:user) { create(:manager) }

        it { should have_permitted_events_including :add_message_to_case,
                                                    :close,
                                                    :destroy_case,
                                                    :edit_case }

        it 'renders the show page' do
          expect(response).to have_rendered(:show)
        end
      end

      context 'as the previously assigned responder' do
        let(:user) { responder }

        it 'filtered permitted_events to be empty' do
          expect(assigns(:filtered_permitted_events)).to be_empty
        end

        it 'renders case details page' do
          expect(response).to render_template :show
        end
      end

      context 'as another responder' do
        let(:user) { create(:responder) }

        it 'filtered permitted_events to be empty' do
          expect(assigns(:filtered_permitted_events)).to be_empty
        end

        it 'renders case details page' do
          expect(response).to render_template :show
        end
      end
    end

  end

  describe 'POST create' do
    context 'as an authenticated responder' do
      before { sign_in responder }

      let(:params) do
        {
          correspondence_type: 'foi',
          case_foi: {
            type: 'Standard',
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
        expect{ subject }.not_to change { Case::Base.count }
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
            correspondence_type: 'foi',
            case_foi: {
              requester_type: 'member_of_the_public',
              type: 'Standard',
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

        let(:created_case) { Case::Base.first }

        it 'makes a DB entry' do
          expect { post :create, params: params }.
            to change { Case::Base.count }.by 1
        end

        it 'uses the params provided' do
          post :create, params: params

          expect(created_case.requester_type).to eq 'member_of_the_public'
          expect(created_case.type).to eq 'Case::FOI::Standard'
          expect(created_case.name).to eq 'A. Member of Public'
          expect(created_case.postal_address).to eq '102 Petty France'
          expect(created_case.email).to eq 'member@public.com'
          expect(created_case.subject).to eq 'FOI request from controller spec'
          expect(created_case.message).to eq 'FOI about prisons and probation'
          expect(created_case.received_date).to eq Time.zone.today
        end

        it "create a internal review for timeliness" do
          params[:case_foi][:type] = 'TimelinessReview'
          post :create, params: params
          expect(created_case.type).to eq 'Case::FOI::TimelinessReview'
        end

        it "create a internal review for compliance" do
          params[:case_foi][:type] = 'ComplianceReview'
          post :create, params: params
          expect(created_case.type).to eq 'Case::FOI::ComplianceReview'
        end

        describe 'flag_for_clearance' do
          let!(:service) do
            double(CaseFlagForClearanceService, call: true).tap do |svc|
              allow(CaseFlagForClearanceService).to receive(:new).and_return(svc)
            end
          end

          it 'does not flag for clearance if parameter is not set' do
            params[:case_foi].delete(:flag_for_disclosure_specialists)
            expect { post :create, params: params }
              .not_to change { Case::Base.count }
            expect(service).not_to have_received(:call)
          end

          it "returns an error message if parameter is not set" do
            params[:case_foi].delete(:flag_for_disclosure_specialists)
            post :create, params: params
            expect(assigns(:case).errors).to have_key(:flag_for_disclosure_specialists)
            expect(response).to have_rendered(:new)
          end

          it "flags the case for clearance if parameter is true" do
            params[:case_foi][:flag_for_disclosure_specialists] = 'yes'
            post :create, params: params
            expect(service).to have_received(:call)
          end

          it "does not flag the case for clearance if parameter is false" do
            params[:case_foi][:flag_for_disclosure_specialists] = false
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
        expect(assigns(:case)).to eq(Case::Base.first)
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
      let(:expected_params) { BypassParamsManager.new(
        ActionController::Parameters.new({"type"=>"response", "uploaded_files"=>[uploads_key], "id"=>kase.id.to_s, "controller"=>"cases", "action"=>"upload_responses"}))
      }
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

      it 'sets a flash message' do
        allow_any_instance_of(CasesController).to receive(:flash).and_return(flash)
        expect(ResponseUploaderService).to receive(:new).and_return(response_uploader)
        do_upload_responses
        expect(flash[:notice]).to eq "You have uploaded the response for this case."
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
    it 'uses the policy scope' do
      allow(controller).to receive(:policy_scope).and_return(Case::Base.none)
      get :search, params: { query: assigned_case.number }
      expect(controller).to have_received(:policy_scope).with(Case::Base)
    end

    it 'passes the page param to the paginator' do
      paged_cases = double('Paged Cases', decorate: [])
      cases = double('Cases', page: paged_cases, empty?: true)
      allow(Case::Base).to receive(:search).and_return(cases)
      get :search, params: { query: assigned_case.number, page: 'our_pages' }
      expect(cases).to have_received(:page).with('our_pages')
    end
  end

  describe 'GET edit' do
    let(:kase) { create :accepted_case }

    context 'as a logged in non-manager' do

      before(:each)  do
        sign_in responder
        get :edit, params: { id: kase.id }
      end

      it 'redirects to case list' do
        expect(response).to redirect_to root_path
      end

      it 'displays error message in flash' do
        expect(flash[:alert]).to eq 'You are not authorised to edit this case.'
      end
    end
    context 'as a manager' do
      before(:each) do
        sign_in manager
        get :edit, params: { id: kase.id }
      end

      it 'assigns case' do
        expect(assigns(:case)).to eq kase
      end

      it 'renders edit' do
        expect(response).to render_template :edit
      end
    end
  end

  describe 'PATCH update', versioning: true do

    # let(:managing_team)                 { create :team_dacu_disclosure }
    # let(:dacu_disclosure_specialist)    { managing_team.users.first }
    let(:service)                       { double CaseUpdaterService }
    let(:kase)                          { create :accepted_case }
    let(:edit_params) do
      ActionController::Parameters.new({
        correspondence_type: 'foi',
        case_foi:  {
          name: 'Tony Blair',
          email: 'tb@blairco.pol',
          postal_address: '2, Vinery Way London W6 0LQ',
          requester_type: 'offender',
          received_date_dd: '1',
          received_date_mm: '10',
          received_date_yyyy: '2017',
          subject: 'TEST case',
          message: 'Lorem ipsum dolor',
        },
        commit: 'Submit',
        id:  kase.id.to_s
      })
    end

    let(:expected_params) do
      ActionController::Parameters.new({
       name: 'Tony Blair',
       email: 'tb@blairco.pol',
       postal_address: '2, Vinery Way London W6 0LQ',
       requester_type: 'offender',
       received_date_dd: '1',
       received_date_mm: '10',
       received_date_yyyy: '2017',
       subject: 'TEST case',
       message: 'Lorem ipsum dolor',
     }).permit(
        :name,
        :email,
        :postal_address,
        :requester_type,
        :received_date_dd,
        :received_date_mm,
        :received_date_yyyy,
        :subject,
        :message,
        :correspondence_type_id
      )
    end

    let(:date)    { Time.local(2017, 10, 3) }

    context 'as a logged in non-manager' do
      before(:each) do
        Timecop.freeze(date) do
          sign_in responder
          patch :update, params: edit_params.to_unsafe_hash
        end
      end

      it 'redirects' do
        Timecop.freeze(date) do
          expect(response).to redirect_to root_path
        end
      end

      it 'gives error in flash' do
        Timecop.freeze(date) do
          expect(flash[:alert]).to eq 'You are not authorised to edit this case.'
        end
      end
    end

    context 'as a manager' do

      let(:manager)   { create :manager, managing_teams: [find_or_create(:team_dacu)] }

      before(:each) {
        sign_in manager
      }

      it 'calls case updater service' do
        Timecop.freeze(date) do
          expect(CaseUpdaterService).to receive(:new).
            with(manager, kase, expected_params).
            and_return(service)
          expect(service).to receive(:call)
          allow(service).to receive(:result)

          patch :update, params: edit_params.to_unsafe_hash
        end
      end


      it 'creates a papertrail version with the current user as whodunnit' do
        Timecop.freeze(date) do
          patch :update, params: edit_params.to_unsafe_hash
          expect(kase.versions.size).to eq 2
          expect(kase.versions.last.whodunnit).to eq manager.id.to_s
        end
      end
    end
    context 'case is an appeal' do
      let(:kase)     { create :accepted_compliance_review}
      context 'as a logged in non-manager' do
        before(:each) do
          Timecop.freeze(date) do
            sign_in responder
            patch :update, params: edit_params.to_unsafe_hash
          end
        end

        it 'redirects' do
          Timecop.freeze(date) do
            expect(response).to redirect_to root_path
          end
        end

        it 'gives error in flash' do
          Timecop.freeze(date) do
            expect(flash[:alert]).to eq 'You are not authorised to edit this case.'
          end
        end
      end
    end

  end

end

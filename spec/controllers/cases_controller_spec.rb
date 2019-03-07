require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')


def stub_current_case_finder_cases_with(result)
  pager = double 'Kaminari Pager', decorate: result
  cases_by_deadline = double 'ActiveRecord Cases by Deadline', page: pager
  cases = double 'ActiveRecord Cases', by_deadline: cases_by_deadline
  page = instance_double GlobalNavManager::Page, cases: cases
  gnm = instance_double GlobalNavManager, current_page_or_tab: page
  allow(GlobalNavManager).to receive(:new).and_return gnm
  gnm
end

def stub_current_case_finder_for_closed_cases_with(result)
  pager = double 'Kaminari Pager', decorate: result
  cases_by_last_transitioned_date = double 'ActiveRecord Cases by last transitioned', page: pager
  cases = double 'ActiveRecord Cases', by_last_transitioned_date: cases_by_last_transitioned_date
  page = instance_double GlobalNavManager::Page, cases: cases
  gnm = instance_double GlobalNavManager, current_page_or_tab: page
  allow(cases_by_last_transitioned_date).to receive(:limit).and_return(cases_by_last_transitioned_date)
  allow(GlobalNavManager).to receive(:new).and_return gnm
  gnm
end

RSpec.describe CasesController, type: :controller do

  let(:all_cases)             { create_list(:case, 5)   }
  let(:first_case)            { all_cases.first         }
  let(:manager)               { find_or_create :disclosure_specialist_bmt }
  let(:responder)             { find_or_create :foi_responder }
  let(:another_responder)     { create :responder }
  let(:responding_team)       { responder.responding_teams.first }
  let(:co_responder)          { create :responder,
                                       responding_teams: [responding_team] }
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }
  let(:team_dacu_disclosure)  { find_or_create :team_dacu_disclosure }
  let(:approver_responder)    { create :approver_responder,
                                       responding_teams: [responding_team],
                                       approving_team: team_dacu_disclosure }
  let(:unassigned_case)       { create(:case) }
  let(:assigned_case)         { create :assigned_case,
                                        responding_team: responding_team }
  let(:accepted_case)         { create :accepted_case,
                                       responder: responder,
                                       responding_team: responding_team }
  let(:responded_case)        { create :responded_case,
                                       responder: responder,
                                       responding_team: responding_team,
                                       received_date: 5.days.ago }
  let(:case_with_response)    { create :case_with_response,
                                       responder: responder,
                                       responding_team: responding_team }
  let(:flagged_case)          { create :assigned_case, :flagged,
                                        responding_team: responding_team,
                                        approving_team: team_dacu_disclosure }
  let(:flagged_accepted_case) { create :accepted_case, :flagged_accepted,
                                       responding_team: responding_team,
                                       approver: disclosure_specialist,
                                       responder: responder}

  let(:assigned_trigger_case)               { create :assigned_case, :flagged_accepted,
                                                      approver: disclosure_specialist }
  let(:pending_dacu_clearance_case)         { create :pending_dacu_clearance_case,
                                                     responding_team: responding_team }
  let(:case_accepted_by_approver_responder) { create :accepted_case,
                                                     :flagged_accepted,
                                                     approver:  approver_responder,
                                                     responder: approver_responder,
                                                     responding_team: responding_team }
  let(:case_only_accepted_for_approving) { create :accepted_case,
                                                  :flagged_accepted,
                                                  approver:  approver_responder,
                                                  responder: another_responder,
                                                  responding_team: another_responder.responding_teams.first }


  describe '#set_cases' do
    before(:each) do
      user = find_or_create :foi_responder
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
        expect(assigns(:assignments)).to eq [ kase.responder_assignment,
                                              kase.approver_assignments.first ]
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
      context 'html' do
        it "be redirected to signin if trying to update a specific case" do
          get :closed_cases
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'csv format' do
        it 'generates a file and downloads it' do
          expect(CSVGenerator).not_to receive(:new)

          get :closed_cases, format: 'csv'
          expect(response.status).to eq 401
          expect(response.header['Content-Type']).to eq 'text/csv; charset=utf-8'
          expect(response.body).to eq 'You need to sign in or sign up before continuing.'
        end
      end
    end
  end

  context "as an authenticated manager" do

    before { sign_in manager }

    describe 'GET closed_cases' do

      it 'assigns cases returned by CaseFinderService' do
        stub_current_case_finder_for_closed_cases_with(:closed_cases_result)
        get :closed_cases
        expect(assigns(:cases)).to eq :closed_cases_result
      end

      it 'passes page param to the paginator' do
        gnm = stub_current_case_finder_for_closed_cases_with(:closed_cases_result)
        get :closed_cases, params: { page: 'our_page' }
        expect(gnm.current_page_or_tab.cases.by_last_transitioned_date)
          .to have_received(:page).with('our_page')
      end

      context 'html format' do
        it 'renders the closed cases page' do
          get :closed_cases
          expect(response).to render_template :closed_cases
        end
      end

      context 'csv format' do
        it 'generates a file and downloads it' do
          expect(CSVGenerator).to receive(:filename).with('closed').and_return('abc.csv')

          get :closed_cases, format: 'csv'
          expect(response.status).to eq 200
          expect(response.header['Content-Disposition']).to eq %q{attachment; filename="abc.csv"}
          expect(response.body).to eq CSV.generate_line(CSVExporter::CSV_COLUMN_HEADINGS)
        end

        it 'does not paginate the result set' do
          gnm = stub_current_case_finder_for_closed_cases_with(:closed_cases_result)
          get :closed_cases, format: 'csv', params: { page: 'our_page' }

          expect(gnm.current_page_or_tab.cases.by_last_transitioned_date)
              .not_to have_received(:page).with('our_page')
        end
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
            outcome_abbreviation: outcome.abbreviation,
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
        let(:responder)   { sar.responder }
        let(:sar)         { create :accepted_sar }

        before(:all) do
          CaseClosure::MetadataSeeder.seed!
        end

        after(:all) do
          CaseClosure::MetadataSeeder.unseed!
        end

        before do
          allow(ActionNotificationsMailer).to receive_message_chain(:notify_team,
                                                                    :deliver_later)
        end

        it "closes a case that has been responded to" do
          sign_in responder
          patch :process_respond_and_close, params: sar_closure_params(sar)
          expect(Case::SAR.first.current_state).to eq 'closed'
          expect(Case::SAR.first.refusal_reason_id).to eq CaseClosure::RefusalReason.sar_tmm.id
          expect(Case::SAR.first.date_responded).to eq 3.days.ago.to_date
          expect(ActionNotificationsMailer)
            .to have_received(:notify_team)
                  .with(sar.managing_team, sar, 'Case closed')
        end

        context 'not the assigned responder' do
          it "does not progress the case" do
            sign_in another_responder
            patch :process_respond_and_close, params: sar_closure_params(sar)
            expect(Case::SAR.first.current_state).to eq 'drafting'
            expect(Case::SAR.first.date_responded).to be nil
            expect(ActionNotificationsMailer)
              .not_to have_received(:notify_team)
                    .with(sar.managing_team, sar, 'Case closed')
          end
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

      it 'sets @current_tab_name to all cases for "All open cases tab"' do
        stub_current_case_finder_cases_with(:my_open_cases_result)
        get :my_open_cases, params: { tab: 'in_time' }
        expect(assigns(:current_tab_name)).to eq 'my_cases'
      end

      context 'html request' do
        it 'renders the index template' do
          stub_current_case_finder_cases_with(:my_open_cases_result)
          get :my_open_cases, params: { tab: 'in_time' }
          expect(response).to render_template(:index)
        end
      end

      context 'csv request' do
        it 'downloads a csv file' do
          expect(CSVGenerator).to receive(:filename).with('my-open').and_return('abc.csv')

          get :my_open_cases, params: { tab: 'in_time' }, format: 'csv'
          expect(response.status).to eq 200
          expect(response.header['Content-Disposition']).to eq %q{attachment; filename="abc.csv"}
          expect(response.body).to eq CSV.generate_line(CSVExporter::CSV_COLUMN_HEADINGS)
        end
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
        let(:user) { find_or_create(:foi_responder) }

        it { should have_permitted_events_including :link_a_case }

        it 'renders case details page' do
          expect(response).to render_template :show
        end


      end
    end

    context 'viewing a flagged accepted case outside the escalation period' do
      let(:user) { flagged_accepted_case.responder }

      context 'outside the escalation_period' do
        before do
          sign_in user
          flagged_accepted_case.update(escalation_deadline: 2.days.ago)
          get :show, params: { id: flagged_accepted_case.id   }
        end

        it 'should permit adding a response' do

          it {should have_permitted_events_including :add_message_to_case,
                                                     :add_responses,
                                                     :link_a_case,
                                                     :reassign_user,
                                                     :remove_linked_case,
                                                     :upload_responses }
        end

        it 'renders the show page' do
          expect(response).to have_rendered(:show)
        end
      end

      context 'inside the escalation period' do
        before do
          sign_in user
          flagged_accepted_case.update(escalation_deadline: 2.days.from_now)
          get :show, params: { id: flagged_accepted_case.id   }
        end

        it 'should not permit adding a response' do
          it {should have_permitted_events :add_message_to_case,
                                           :link_a_case,
                                           :reassign_user,
                                           :remove_linked_case,
                                           :upload_responses }
        end

        it 'renders the show page' do
          expect(response).to have_rendered(:show)
        end
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
          assigned_case.correspondence_type.reload
          responder_assignment = assigned_case.assignments.last
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
        let(:user) { another_responder }

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
        let(:user) { another_responder }

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
          expect(assigns(:filtered_permitted_events))
            .to match_array [:add_message_to_case]
        end

        it 'renders case details page' do
          expect(response).to render_template :show
        end
      end

      context 'as another responder' do
        let(:user) { another_responder }

        it 'filtered permitted_events to be empty' do
          expect(assigns(:filtered_permitted_events)).to be_empty
        end

        it 'renders case details page' do
          expect(response).to render_template :show
        end
      end
    end

  end

  describe 'GET respond' do

    let(:responder)            { find_or_create(:foi_responder) }
    let(:another_responder)    { create(:responder)             }

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

      context 'calling the action from an AJAX request' do
        it 'does not call the service' do
          patch :flag_for_clearance, params: params, xhr: true
          expect(CaseFlagForClearanceService).not_to have_received(:new)
        end

        it 'returns an error' do
          patch :flag_for_clearance, params: params, xhr: true
          expect(response).to have_http_status 401
        end
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

      context 'calling the action from an AJAX request' do
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
          expect(response).to have_rendered('cases/flag_for_clearance.js.erb')
        end

        it 'returns a success code' do
          patch :flag_for_clearance, params: params, xhr: true
          expect(response).to have_http_status 200
        end
      end

      context 'calling the action from a HTTP request' do
        it 'instantiates and calls the service' do
          patch :flag_for_clearance, params: params
          expect(CaseFlagForClearanceService)
            .to have_received(:new).with(user: manager,
                                         kase: unflagged_case_decorated,
                                         team: BusinessUnit.dacu_disclosure)
          expect(service).to have_received(:call)
        end

        it 'renders the view' do
          patch :flag_for_clearance, params: params
          expect(response).to redirect_to(case_path(unflagged_case_decorated))
        end

        it 'returns a success code' do
          patch :flag_for_clearance, params: params
          expect(response).to have_http_status 302
        end
      end
    end

    context 'as an authenticated disclosure_specialist' do
      before do
        sign_in disclosure_specialist
      end

      context 'calls the action from an AJAX request' do
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
          expect(response).to have_rendered('cases/flag_for_clearance.js.erb')
        end

        it 'returns success' do
          patch :flag_for_clearance, params: params, xhr: true
          expect(response).to have_http_status 200
        end
      end

      context 'calls the action from a HTTP request' do
        it 'instantiates and calls the service' do
          patch :flag_for_clearance, params: params
          expect(CaseFlagForClearanceService)
            .to have_received(:new).with(user: disclosure_specialist,
                                         kase: unflagged_case_decorated,
                                         team: BusinessUnit.dacu_disclosure)
          expect(service).to have_received(:call)
        end

        it 'renders the view' do
          patch :flag_for_clearance, params: params
          expect(response).to redirect_to case_path(unflagged_case_decorated)
        end

        it 'returns success' do
          patch :flag_for_clearance, params: params
          expect(response).to have_http_status 302
        end
      end
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

    context 'ICO cases' do
      let(:kase) { create :accepted_ico_foi_case }

      before(:each) do
        sign_in manager
        get :edit, params: { id: kase.id }
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

  describe 'GET new_overturned_ico' do

    let(:ico_sar)             { create :ico_sar_case }
    let(:sar)                 { create :sar_case }
    let(:overturned_ico_case) { create :overturned_ico_sar }

    context 'logged in as manager' do

      before { sign_in manager }

      context 'valid params' do
        before do
          service = double(NewOverturnedIcoCaseService,
                           call: nil,
                           error?: false,
                           success?: true,
                           original_ico_appeal: ico_sar,
                           original_case: sar,
                           overturned_ico_case: overturned_ico_case)
          params = ActionController::Parameters.new({ id: ico_sar.id })
          expect(NewOverturnedIcoCaseService).to receive(:new).with(ico_sar.id.to_s).and_return(service)
          get :new_overturned_ico, params: params.to_unsafe_hash
        end

        it 'is success' do
          expect(response).to be_success
        end

        it 'assigns a new overturned case to @case' do
          expect(assigns(:case)).to eq overturned_ico_case
        end

        it 'renders the new overturned ico case page' do
          expect(response).to render_template('cases/new')
        end
      end

      context 'invalid params' do
        before do
          service = double(NewOverturnedIcoCaseService,
                           call: nil,
                           error?: true,
                           success?: false,
                           original_ico_appeal: ico_sar,
                           original_case: sar,
                           overturned_ico_case: overturned_ico_case)
          params = ActionController::Parameters.new({ id: ico_sar.id })
          expect(NewOverturnedIcoCaseService).to receive(:new).with(ico_sar.id.to_s).and_return(service)
          get :new_overturned_ico, params: params.to_unsafe_hash
        end

        it 'is bad_request' do
          expect(response).to be_bad_request
        end

        it 'assigns the original ico appeal to @case' do
          expect(assigns(:case)).to eq ico_sar
        end

        it 'renders the show page for the ico appeal' do
          expect(response).to render_template('cases/show')
        end
      end
    end

    # context 'logged in as responder' do
    #   before { sign_in responder }
    # end

  end

end

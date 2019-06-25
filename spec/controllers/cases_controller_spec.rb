require 'rails_helper'

RSpec.describe CasesController, type: :controller do
  let(:all_cases)             { create_list(:case, 5)   }
  let(:first_case)            { all_cases.first         }
  let(:manager)               { find_or_create :disclosure_specialist_bmt }
  let(:responder)             { find_or_create :foi_responder }
  let(:another_responder)     { create :responder }
  let(:manager_approver)      { create :manager_approver }
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

  # # Index is not used, as users are redirected to FiltersController
  # describe '#index' do
  #   let(:decorate_result) { double 'decorated_result' }
  #   let(:pager) { double 'Kaminari Pager', decorate: decorate_result }
  #   let(:cases) { double 'ActiveRecord Cases', page: pager }
  #   let(:finder) { instance_double(CaseFinderService, scope: cases) }
  #
  #   before do
  #     allow(CaseFinderService).to receive(:new).and_return(finder)
  #     allow(finder).to receive(:for_params).and_return(finder)
  #   end
  #
  #   context "as an anonymous user" do
  #     it "be redirected to signin if trying to list of questions" do
  #       get :index
  #       expect(response).to redirect_to(new_user_session_path)
  #     end
  #   end
  #
  #   context 'as an authenticated user' do
  #     before { sign_in manager }
  #
  #     it 'renders the index page' do
  #       get :index
  #       expect(response).to render_template :index
  #     end
  #
  #     it 'assigns cases returned by CaseFinderService' do
  #       get :index
  #       expect(CaseFinderService).to have_received(:new).with(manager)
  #       expect(assigns(:cases)).to eq decorate_result
  #     end
  #
  #     it 'sets @current_tab_name' do
  #       get :index
  #       expect(assigns(:current_tab_name)).to eq 'all_cases'
  #     end
  #
  #     it 'sets @can_add_case to true' do
  #       get :index
  #       expect(assigns(:can_add_case)).to eq true
  #     end
  #   end
  # end

  describe '#show' do

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

  describe '#edit' do
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

  describe '#update', versioning: true do

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

require "rails_helper"

describe CasesController, type: :controller do
  describe '#show' do
    let(:manager)            { create :manager }
    let(:responder)          { create :responder }
    let(:another_responder)  { create :responder }
    let(:responding_team)    { responder.responding_teams.first }
    let(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
    let(:disclosure_specialist) { create :disclosure_specialist }
    let(:assigned_case)      { create :assigned_case,
                                      responding_team: responding_team }
    let(:accepted_case)      { create :accepted_case, responder: responder }
    let(:unassigned_case)    { create(:case) }
    let(:case_with_response) { create :case_with_response, responder: responder }
    let(:flagged_accepted_case) { create :accepted_case, :flagged_accepted,
                                         responding_team: responding_team,
                                         approver: disclosure_specialist,
                                         responder: responder}

    it 'authorises' do
      sign_in manager
      expect_any_instance_of(ConfigurableStateMachine::Machine).to receive(:predicate_is_true?).with(
          predicate: 'Case::FOI::StandardPolicy#can_request_further_clearance?',
          user: manager).and_return(true)
      expect {
        get :show, params: { id: accepted_case.id }
      }.to require_permission(:show?)
             .with_args(manager, accepted_case)
             .disallowing(:can_accept_or_reject_responder_assignment?)
    end

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

        it {should have_permitted_events_including(:add_message_to_case,
                                                   :assign_responder,
                                                   :destroy_case,
                                                   :edit_case,
                                                   :flag_for_clearance )}

        it 'renders the show template' do
          expect(response).to render_template(:show)
        end
      end

      context 'as a responder' do
        let(:user) { create(:responder) }

        it { should have_permitted_events :link_a_case,
                                          :remove_linked_case}

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

      it { should have_permitted_events_including :add_message_to_case,
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

        it {should have_permitted_events :add_message_to_case,
                                         :assign_to_new_team,
                                         :destroy_case,
                                         :edit_case,
                                         :flag_for_clearance,
                                         :link_a_case,
                                         :remove_linked_case,
                                         :request_further_clearance }


        it 'has filtered permitted events' do
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

        it { should have_permitted_events :link_a_case, :remove_linked_case }

        it 'has no filtered permitted events' do
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

        it { should have_permitted_events :link_a_case, :remove_linked_case }

        it 'has no filtered permitted_events' do
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

        it { should have_permitted_events :link_a_case, :remove_linked_case }

        it 'has no filtered permitted events' do
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

        it { should have_permitted_events :link_a_case, :remove_linked_case }

        it 'has no filtered permitted events' do
          expect(assigns(:filtered_permitted_events)).to be_empty
        end

        it 'renders case details page' do
          expect(response).to render_template :show
        end
      end

      context 'as another responder' do
        let(:user) { create(:responder) }

        it { should have_permitted_events :link_a_case, :remove_linked_case }

        it 'has no filtered permitted events' do
          expect(assigns(:filtered_permitted_events)).to be_empty
        end

        it 'renders case details page' do
          expect(response).to render_template :show
        end
      end
    end

  end


end

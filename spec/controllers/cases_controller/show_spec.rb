require "rails_helper"

describe CasesController, type: :controller do # rubocop:disable RSpec/FilePath
  describe "#show" do
    let(:manager)            { create :manager }
    let(:responding_team)    { find_or_create :foi_responding_team }
    let(:responder)          { find_or_create :foi_responder }
    let(:another_responder)  { create :responder }
    let(:team_dacu_disclosure) { create :team_dacu_disclosure }
    let(:disclosure_specialist) { find_or_create :disclosure_specialist }
    let(:assigned_case) do
      create :assigned_case,
             responding_team:
    end
    let(:accepted_case)      { create :accepted_case }
    let(:unassigned_case)    { create(:case) }
    let(:case_with_response) { create :case_with_response }
    let(:flagged_accepted_case) do
      create :accepted_case, :flagged_accepted,
             responding_team:,
             approver: disclosure_specialist
    end

    it "authorises" do
      sign_in manager
      expect {
        get :show, params: { id: accepted_case.id }
      }.to require_permission(:show?)
             .with_args(manager, accepted_case)
             .disallowing(:can_accept_or_reject_responder_assignment?)
    end

    it "retrieves message_text error from the flash" do
      sign_in responder

      get :show, params: { id: accepted_case.id },
                 flash: { "case_errors" => { message_text: ["cannot be blank"] } }

      expect(assigns(:case).errors.messages[:message_text].first)
        .to eq("cannot be blank")
    end

    it "syncs case transitions for user" do
      sign_in responder

      expect(CasesUsersTransitionsTracker).to receive(:sync_for_case_and_user).with(accepted_case, responder)
      get :show, params: { id: accepted_case.id }
    end

    context "when viewing an unassigned case" do
      before do
        sign_in user
        get :show, params: { id: unassigned_case.id }
      end

      context "when an anonymous user" do
        let(:user) { "" }

        it { is_expected.to have_nil_permitted_events }

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context "with an authenticated manager" do
        let(:user) { create(:manager) }

        it {
          expect(controller).to have_permitted_events_including(:add_message_to_case,
                                                                :assign_responder,
                                                                :destroy_case,
                                                                :edit_case,
                                                                :flag_for_clearance)
        }

        it "renders the show template" do
          expect(response).to render_template(:show)
        end
      end

      context "with a responder" do
        let(:user) { find_or_create(:foi_responder) }

        it {
          expect(controller).to have_permitted_events :link_a_case,
                                                      :remove_linked_case
        }

        it "renders case details page" do
          expect(response).to render_template :show
        end
      end
    end

    context "when viewing a flagged accepted case outside the escalation period" do
      let(:user) { flagged_accepted_case.responder }

      context "and outside the escalation_period" do
        before do
          sign_in user
          flagged_accepted_case.update!(escalation_deadline: 2.days.ago)
          get :show, params: { id: flagged_accepted_case.id }
        end

        it "permits adding a response" do
          expect(controller).to have_permitted_events_including :add_message_to_case,
                                                                :add_responses,
                                                                :link_a_case,
                                                                :reassign_user,
                                                                :remove_linked_case,
                                                                :upload_responses
        end

        it "renders the show page" do
          expect(response).to have_rendered(:show)
        end
      end

      context "and inside the escalation period" do
        before do
          sign_in user
          flagged_accepted_case.update!(escalation_deadline: 2.days.from_now)
          get :show, params: { id: flagged_accepted_case.id }
        end

        it "does not permit adding a response" do
          expect(controller).to have_permitted_events :add_message_to_case,
                                                      :link_a_case,
                                                      :reassign_user,
                                                      :remove_linked_case,
                                                      :remove_response,
                                                      :upload_responses
        end

        it "renders the show page" do
          expect(response).to have_rendered(:show)
        end
      end
    end

    context "when viewing an assigned_case" do
      before do
        sign_in user
        allow(CasesUsersTransitionsTracker).to receive(:update_tracker_for)
        get :show, params: { id: assigned_case.id }
      end

      context "with an anonymous user" do
        let(:user) { "" }

        it { is_expected.to have_nil_permitted_events }

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context "with an authenticated manager" do
        let(:user) { create(:manager) }

        it {
          expect(controller).to have_permitted_events :add_message_to_case,
                                                      :assign_to_new_team,
                                                      :destroy_case,
                                                      :edit_case,
                                                      :flag_for_clearance,
                                                      :link_a_case,
                                                      :remove_linked_case,
                                                      :request_further_clearance
        }

        it "has filtered permitted events" do
          expect(assigns(:filtered_permitted_events)).to eq %i[add_message_to_case assign_to_new_team destroy_case edit_case flag_for_clearance]
        end

        it "renders the show template" do
          expect(response).to render_template(:show)
        end
      end

      context "with a responder of the assigned responding team" do
        let(:user)             { responder }
        let(:press_office)     { create :team_press_office }
        let(:press_officer)    { find_or_create :press_officer }

        before do
          team_dacu_disclosure
          find_or_create :default_private_officer
        end

        it { is_expected.to have_nil_permitted_events }

        it "renders the show template for the responder assignment" do
          assigned_case.correspondence_type.reload
          responder_assignment = assigned_case.assignments.last
          CaseFlagForClearanceService.new(user: press_officer, kase: assigned_case, team: press_office).call
          expect(response)
            .to redirect_to(edit_case_assignment_path(
                              assigned_case,
                              responder_assignment.id,
                            ))
        end

        it "does not update the message tracker for the user" do
          expect(CasesUsersTransitionsTracker)
            .not_to have_received(:update_tracker_for)
                      .with(accepted_case, user)
        end
      end

      context "with a responder of another responding team" do
        let(:user) { another_responder }

        it { is_expected.to have_permitted_events :link_a_case, :remove_linked_case }

        it "has no filtered permitted events" do
          expect(assigns(:filtered_permitted_events)).to be_empty
        end

        it "renders case details page" do
          expect(response).to render_template :show
        end
      end
    end

    context "when viewing a case in drafting" do
      let(:accepted_case) { create(:accepted_case) }

      before do
        sign_in user
        get :show, params: { id: accepted_case.id }
      end

      context "with an anonymous user" do
        let(:user) { "" }

        it { is_expected.to have_nil_permitted_events }

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context "with an authenticated manager" do
        let(:user) { create(:manager) }

        it {
          expect(controller).to have_permitted_events_including :add_message_to_case,
                                                                :assign_to_new_team,
                                                                :destroy_case,
                                                                :edit_case,
                                                                :flag_for_clearance
        }

        it "renders the show page" do
          expect(response).to have_rendered(:show)
        end
      end

      context "with the assigned responder" do
        context "and unflagged case" do
          let(:user) { accepted_case.responder }

          it {
            expect(controller).to have_permitted_events_including :add_message_to_case,
                                                                  :add_responses,
                                                                  :reassign_user
          }

          it "renders the show page" do
            expect(response).to have_rendered(:show)
          end
        end
      end

      context "with another responder" do
        let(:user) { create(:responder) }

        it { is_expected.to have_permitted_events :link_a_case, :remove_linked_case }

        it "has no filtered permitted_events" do
          expect(assigns(:filtered_permitted_events)).to be_empty
        end

        it "renders case details page" do
          expect(response).to render_template :show
        end
      end
    end

    context "when viewing a case_with_response" do
      before do
        sign_in user
        get :show, params: { id: case_with_response.id }
      end

      context "with an anonymous user" do
        let(:user) { "" }

        it { is_expected.to have_nil_permitted_events }

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context "with an authenticated manager" do
        let(:user) { create(:manager) }

        it {
          expect(controller).to have_permitted_events_including :add_message_to_case,
                                                                :destroy_case,
                                                                :edit_case,
                                                                :flag_for_clearance
        }

        it "renders the show page" do
          expect(response).to have_rendered(:show)
        end
      end

      context "with the assigned responder" do
        let(:user) { case_with_response.responder }

        it {
          expect(controller).to have_permitted_events_including :add_message_to_case,
                                                                :add_responses,
                                                                :respond,
                                                                :remove_response
        }

        it "renders the show page" do
          expect(response).to have_rendered(:show)
        end
      end

      context "with another responder" do
        let(:user) { create(:responder) }

        it { is_expected.to have_permitted_events :link_a_case, :remove_linked_case }

        it "has no filtered permitted events" do
          expect(assigns(:filtered_permitted_events)).to be_empty
        end

        it "renders case details page" do
          expect(response).to render_template :show
        end
      end
    end

    context "when viewing a responded_case" do
      let(:responded_case) { create(:responded_case, received_date: 5.days.ago) }

      before do
        sign_in user
        get :show, params: { id: responded_case.id }
      end

      context "with an anonymous user" do
        let(:user) { "" }

        it { is_expected.to have_nil_permitted_events }

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context "with an authenticated manager" do
        let(:user) { create(:manager) }

        it {
          expect(controller).to have_permitted_events_including :add_message_to_case,
                                                                :close,
                                                                :destroy_case,
                                                                :edit_case
        }

        it "renders the show page" do
          expect(response).to have_rendered(:show)
        end
      end

      context "with the previously assigned responder" do
        let(:user) { responder }

        it {
          expect(controller).to have_permitted_events :add_message_to_case,
                                                      :link_a_case,
                                                      :remove_linked_case
        }

        it "has no filtered permitted events" do
          expect(assigns(:filtered_permitted_events))
            .to include :add_message_to_case
        end

        it "renders case details page" do
          expect(response).to render_template :show
        end
      end

      context "with another responder" do
        let(:user) { create(:responder) }

        it { is_expected.to have_permitted_events :link_a_case, :remove_linked_case }

        it "has no filtered permitted events" do
          expect(assigns(:filtered_permitted_events)).to be_empty
        end

        it "renders case details page" do
          expect(response).to render_template :show
        end
      end
    end

    context "when recording search query click" do
      let(:kase)         { create :case }
      let(:search_query) { create :search_query }
      let(:flash)        do
        ActionDispatch::Flash::FlashHash
                             .new({ query_id: search_query.id })
      end

      before do
        sign_in create(:manager)
      end

      context "and has a search query id" do
        it "records search query to record the click" do
          allow(controller).to receive(:flash).and_return(flash)
          params = ActionController::Parameters.new(id: kase.id.to_s, pos: "4", controller: "cases", action: "show")
          allow(SearchQuery).to receive(:find)
                                   .with(search_query.id)
                                   .and_return(search_query)
          allow(search_query).to receive(:update_for_click)
          get :show, params: params.to_unsafe_hash
          expect(search_query).to have_received(:update_for_click).with(4)
        end
      end

      context "and no flash parameter" do
        it "does not call search query to record the click" do
          allow(controller).to receive(:flash).and_return({})
          params = ActionController::Parameters.new(id: kase.id.to_s, controller: "cases", action: "show")
          expect(SearchQuery).not_to receive(:update_for_click)
          get :show, params: params.to_unsafe_hash
        end
      end
    end
  end
end

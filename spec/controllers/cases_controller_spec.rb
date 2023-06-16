require "rails_helper"

RSpec.describe CasesController, type: :controller do
  let(:manager)               { find_or_create :disclosure_specialist_bmt }
  let(:responder)             { find_or_create :foi_responder }
  let(:another_responder)     { create :responder }
  let(:responding_team)       { responder.responding_teams.first }
  let(:co_responder)          do
    create :responder,
           responding_teams: [responding_team]
  end
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }
  let(:team_dacu_disclosure)  { find_or_create :team_dacu_disclosure }
  let(:approver_responder)    do
    create :approver_responder,
           responding_teams: [responding_team],
           approving_team: team_dacu_disclosure
  end
  let(:unassigned_case)       { create(:case) }
  let(:assigned_case)         do
    create :assigned_case,
           responding_team:
  end
  let(:accepted_case) do
    create :accepted_case,
           responder:,
           responding_team:
  end
  let(:responded_case) do
    create :responded_case,
           responder:,
           responding_team:,
           received_date: 5.days.ago
  end
  let(:case_with_response) do
    create :case_with_response,
           responder:,
           responding_team:
  end

  let(:flagged_accepted_case) do
    create :accepted_case, :flagged_accepted,
           responding_team:,
           approver: disclosure_specialist,
           responder:
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
      expect(assigns(:case_transitions)).to be_an_instance_of(Draper::CollectionDecorator)
      expect(assigns(:case_transitions).map(&:class)).to eq [CaseTransitionDecorator, CaseTransitionDecorator]
    end
  end

  describe "#set_assignments" do
    context "current user is only in responder team" do
      it "instantiates the assignments for responders" do
        sign_in responder
        get :show, params: { id: accepted_case.id }
        expect(assigns(:assignments)).to eq [accepted_case.responder_assignment]
      end
    end

    context "current user is another responder on same team" do
      let(:kase) { accepted_case }

      it "instantiates responding assignment" do
        sign_in co_responder
        get :show, params: { id: kase.id }
        expect(assigns(:assignments)).to eq [kase.responder_assignment]
      end
    end

    context "current_user is in both responder and approver team" do
      it "instantiates both the assignments for responders and approvers" do
        kase = case_accepted_by_approver_responder
        sign_in approver_responder
        get :show, params: { id: kase.id }
        expect(assigns(:assignments)).to eq [kase.responder_assignment,
                                             kase.approver_assignments.first]
      end
    end

    context "current user is responder on a different team" do
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

  describe "#show" do
    it "retrieves message_text error from the flash" do
      sign_in responder

      get :show, params: { id: accepted_case.id },
                 flash: { "case_errors" => { message_text: ["cannot be blank"] } }

      expect(assigns(:case).errors.messages[:message_text].first)
        .to eq("cannot be blank")
    end

    it "syncs case transitions tracker for user" do
      sign_in responder

      stub_find_case(accepted_case.id) do |kase|
        expect(kase).to receive(:sync_transition_tracker_for_user)
                          .with(responder)
      end
      get :show, params: { id: accepted_case.id }
    end

    context "viewing an unassigned case" do
      before do
        sign_in user
        get :show, params: { id: unassigned_case.id }
      end

      context "as an anonymous user" do
        let(:user) { "" }

        it { is_expected.to have_nil_permitted_events }

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context "as an authenticated manager" do
        let(:user) { create(:manager) }

        it {
          expect(subject).to have_permitted_events_including :add_message_to_case,
                                                             :assign_responder,
                                                             :destroy_case,
                                                             :edit_case,
                                                             :flag_for_clearance
        }

        it "renders the show template" do
          expect(response).to render_template(:show)
        end
      end

      context "as a responder" do
        let(:user) { find_or_create(:foi_responder) }

        it { is_expected.to have_permitted_events_including :link_a_case }

        it "renders case details page" do
          expect(response).to render_template :show
        end
      end
    end

    context "viewing a flagged accepted case outside the escalation period" do
      let(:user) { flagged_accepted_case.responder }

      context "outside the escalation_period" do
        before do
          sign_in user
          flagged_accepted_case.update!(escalation_deadline: 2.days.ago)
          get :show, params: { id: flagged_accepted_case.id }
        end

        it "permits adding a response" do
          expect(subject).to have_permitted_events_including :add_message_to_case,
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

      context "inside the escalation period" do
        before do
          sign_in user
          flagged_accepted_case.update!(escalation_deadline: 2.days.from_now)
          get :show, params: { id: flagged_accepted_case.id }
        end

        it "does not permit adding a response" do
          expect(subject).to have_permitted_events :add_message_to_case,
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

    context "viewing an assigned_case" do
      before do
        sign_in user
        allow(CasesUsersTransitionsTracker).to receive(:update_tracker_for)
        get :show, params: { id: assigned_case.id }
      end

      context "as an anonymous user" do
        let(:user) { "" }

        it { is_expected.to have_nil_permitted_events }

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context "as an authenticated manager" do
        let(:user) { create(:manager) }

        it "permitted_events == []" do
          expect(assigns(:filtered_permitted_events)).to eq %i[add_message_to_case assign_to_new_team destroy_case edit_case flag_for_clearance]
        end

        it "renders the show template" do
          expect(response).to render_template(:show)
        end
      end

      context "as a responder of the assigned responding team" do
        let(:user)             { responder }
        let(:press_office)     { find_or_create :team_press_office }
        let(:press_officer)    { find_or_create :press_officer }
        let!(:private_officer) { find_or_create :default_private_officer }

        before do
          team_dacu_disclosure
        end

        it { is_expected.to have_nil_permitted_events }

        it "renders the show template for the responder assignment" do
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

      context "as a responder of another responding team" do
        let(:user) { another_responder }

        it "permitted_events to containe add_message_to_case only" do
          expect(assigns(:filtered_permitted_events)).to be_empty
        end

        it "renders case details page" do
          expect(response).to render_template :show
        end
      end
    end

    context "viewing a case in drafting" do
      let(:accepted_case) { create(:accepted_case) }

      before do
        sign_in user
        get :show, params: { id: accepted_case.id }
      end

      context "as an anonymous user" do
        let(:user) { "" }

        it { is_expected.to have_nil_permitted_events }

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context "as an authenticated manager" do
        let(:user) { create(:manager) }

        it {
          expect(subject).to have_permitted_events_including :add_message_to_case,
                                                             :assign_to_new_team,
                                                             :destroy_case,
                                                             :edit_case,
                                                             :flag_for_clearance
        }

        it "renders the show page" do
          expect(response).to have_rendered(:show)
        end
      end

      context "as the assigned responder" do
        context "unflagged case" do
          let(:user) { accepted_case.responder }

          it {
            expect(subject).to have_permitted_events_including :add_message_to_case,
                                                               :add_responses,
                                                               :reassign_user
          }

          it "renders the show page" do
            expect(response).to have_rendered(:show)
          end
        end
      end

      context "as another responder" do
        let(:user) { another_responder }

        it "filtered permitted_events to be empty" do
          expect(assigns(:filtered_permitted_events)).to be_empty
        end

        it "renders case details page" do
          expect(response).to render_template :show
        end
      end
    end

    context "viewing a case_with_response" do
      before do
        sign_in user
        get :show, params: { id: case_with_response.id }
      end

      context "as an anonymous user" do
        let(:user) { "" }

        it { is_expected.to have_nil_permitted_events }

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context "as an authenticated manager" do
        let(:user) { create(:manager) }

        it {
          expect(subject).to have_permitted_events_including :add_message_to_case,
                                                             :destroy_case,
                                                             :edit_case,
                                                             :flag_for_clearance
        }

        it "renders the show page" do
          expect(response).to have_rendered(:show)
        end
      end

      context "as the assigned responder" do
        let(:user) { case_with_response.responder }

        it {
          expect(subject).to have_permitted_events_including :add_message_to_case,
                                                             :add_responses,
                                                             :respond,
                                                             :remove_response
        }

        it "renders the show page" do
          expect(response).to have_rendered(:show)
        end
      end

      context "as another responder" do
        let(:user) { another_responder }

        it "filtered permitted_events to be empty" do
          expect(assigns(:filtered_permitted_events)).to be_empty
        end

        it "renders case details page" do
          expect(response).to render_template :show
        end
      end
    end

    context "viewing a responded_case" do
      let(:responded_case) { create(:responded_case, received_date: 5.days.ago) }

      before do
        sign_in user
        get :show, params: { id: responded_case.id }
      end

      context "as an anonymous user" do
        let(:user) { "" }

        it { is_expected.to have_nil_permitted_events }

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context "as an authenticated manager" do
        let(:user) { create(:manager) }

        it {
          expect(subject).to have_permitted_events_including :add_message_to_case,
                                                             :close,
                                                             :destroy_case,
                                                             :edit_case
        }

        it "renders the show page" do
          expect(response).to have_rendered(:show)
        end
      end

      context "as the previously assigned responder" do
        let(:user) { responder }

        it "filtered permitted_events to be empty" do
          expect(assigns(:filtered_permitted_events))
            .to match_array [:add_message_to_case]
        end

        it "renders case details page" do
          expect(response).to render_template :show
        end
      end

      context "as another responder" do
        let(:user) { another_responder }

        it "filtered permitted_events to be empty" do
          expect(assigns(:filtered_permitted_events)).to be_empty
        end

        it "renders case details page" do
          expect(response).to render_template :show
        end
      end
    end
  end
end

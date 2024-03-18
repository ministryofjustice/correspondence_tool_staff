require "rails_helper"

RSpec.describe CaseTransitionDecorator, type: :model do
  let(:dacu) { find_or_create :team_dacu }
  let(:dacu_user) { create :manager, managing_teams: [dacu], full_name: "David Attenborough" }
  let(:laa) { create :business_unit, name: "Legal Aid Agency" }
  let(:laa_user) { create :responder, responding_teams: [laa], full_name: "Larry Adler" }
  let(:branston) { find_or_create :team_branston }
  let(:branston_user) { create :branston_user, responding_teams: [branston], full_name: "Brian Rix" }

  let(:ct_assign_responder) do
    create(:case_transition_assign_responder,
           acting_user: dacu_user,
           acting_team: dacu,
           target_team: laa,
           created_at: Time.utc(2017, 4, 10, 13, 22, 44)).decorate
  end
  let(:winter_ct_assign_responder) do
    create(:case_transition_assign_responder,
           acting_user: dacu_user,
           acting_team: dacu,
           target_team: laa,
           created_at: Time.utc(2017, 1, 10, 13, 22, 44)).decorate
  end

  describe "#action_date" do
    context "when winter" do
      it "displays the time in UTC" do
        Timecop.freeze Date.new(2017, 2, 1) do
          expect(winter_ct_assign_responder.action_date)
            .to eq "10 Jan 2017<br>13:22"
        end
      end
    end

    context "when summer" do
      it "formats the creation date taking BST into account" do
        expect(ct_assign_responder.action_date).to eq "10 Apr 2017<br>14:22"
      end
    end
  end

  describe "#user_name" do
    it "returns full name of assigning user" do
      expect(ct_assign_responder.user_name).to eq "David Attenborough"
    end
  end

  describe "#user_team" do
    it "returns full team name of user" do
      expect(ct_assign_responder.user_team).to eq dacu.name
    end
  end

  describe "#event_and_detail" do
    describe "accept_responder_assignment" do
      it "returns expected text" do
        ct = create(:case_transition_accept_responder_assignment,
                    acting_team: dacu).decorate
        event = "Accepted by Business unit"
        details = ""
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    describe "add_responses" do
      it "returns number of files uploaded" do
        ct = create(:case_transition_add_responses).decorate
        event = "Response uploaded"
        details = ""
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    describe "assign responder" do
      it "returns team name to which it has been assigned" do
        event = "Assign responder"
        details = "Assigned to Legal Aid Agency"
        expect(ct_assign_responder.event_and_detail).to eq response(event, details)
      end
    end

    describe "assign_to_new_team" do
      it "returns team name to which it has been assigned" do
        ct = create(:case_transition_assign_to_new_team,
                    acting_user: dacu_user,
                    acting_team: dacu,
                    target_team: laa).decorate

        event = "Assign to new team"
        details = "Assigned to Legal Aid Agency"
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    describe "extend_for_pit" do
      it "returns the reason for extending" do
        ct = create(:case_transition_extend_for_pit,
                    acting_user: dacu_user,
                    message: "Too many vipers",
                    case: create(:accepted_case)).decorate
        event = "Extended for Public Interest Test (PIT)"
        details = "Too many vipers"
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    describe "reject_responder_assignment" do
      it "returns the reason for rejection" do
        ct = create(:case_transition_reject_responder_assignment,
                    acting_team: laa,
                    acting_user: laa_user,
                    message: "Not LAA matter",
                    case: create(:assigned_case)).decorate
        event = "Rejected by Business unit"
        details = "Not LAA matter"
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    describe "respond" do
      context "when non ICO case" do
        it "returns marked as reponded" do
          ct = create(:case_transition_respond).decorate
          event = "Response sent to requester"
          details = ""
          expect(ct.event_and_detail).to eq response(event, details)
        end
      end

      context "when ICO case" do
        it "returns messsage resonse sent to ICO" do
          ico_sar_case = create :ico_sar_case
          ct = create(:case_transition_respond, case: ico_sar_case).decorate
          event = "Response sent to ICO"
          details = ""
          expect(ct.event_and_detail).to eq response(event, details)
        end
      end
    end

    describe "remove_response" do
      it "returns name of event" do
        ct = create(:case_transition_remove_response).decorate
        event = "File removed"
        details = ""
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    describe "add_response_to_flagged_case" do
      it "returns number of files and description of who its with" do
        ct = create(:case_transition_pending_dacu_clearance).decorate
        event = "Response uploaded"
        details = ""
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    describe "reassign_user" do
      it "returns name of event" do
        ct = create(:case_transition_reassign_user).decorate
        action_user = User.find(ct.acting_user_id)
        target_user = User.find(ct.target_user_id)
        event = "Reassign user"
        details = "#{action_user.full_name} re-assigned this case to <strong>#{target_user.full_name}</strong>"
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    describe "progress_for_clearance" do
      it "returns to name of the clearance team" do
        drafting_sar_case = create :sar_being_drafted, :flagged_accepted
        ct = create(:case_transition_progress_for_clearance, case: drafting_sar_case).decorate
        target_team = Team.find(ct.target_team_id)
        event = "Progress for clearance"
        details = "Progressed to #{target_team.name}"
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    describe "Add linkage to a case" do
      it "returns to the number of linked case" do
        accepted_case = create :accepted_case, responder: dacu_user, responding_team: dacu
        ct = create(:case_link_foi_case, case: accepted_case).decorate
        expect(ct.event_and_detail).to eq response("Case linked", "")
      end
    end

    describe "Remove linkage to a case" do
      it "returns to the number of linked case if the case exists" do
        accepted_case = create :accepted_case, responder: dacu_user, responding_team: dacu
        ct = create(:case_remove_link_foi_case, case: accepted_case).decorate
        expect(ct.event_and_detail).to eq response(
          "Linked case removed",
          "Removed the link to <strong>#{accepted_case.number}</strong>",
        )
      end

      it "returns to id of linked case if the case has been deleted" do
        accepted_case = create :accepted_case, responder: dacu_user, responding_team: dacu
        ct = create(:case_remove_link_foi_case, case: accepted_case).decorate
        accepted_case.destroy!
        expect(ct.event_and_detail).to match(/Linked case removed.*Removed the link to case_id:.*#{accepted_case.id}/)
      end
    end

    describe "#event_desc" do
      context "when creating a rejected offender SAR" do
        it "returns expected text" do
          ct = create(:case_invalid_submission_offender_creation,
                      acting_team: branston).decorate
          event = "Rejected case created"
          expect(ct.event_desc).to match(event)
        end
      end

      context "when creating a valid offender SAR" do
        it "returns expected text" do
          ct = create(:case_offender_creation,
                      acting_team: branston).decorate
          event = "Case created"
          expect(ct.event_desc).to match(event)
        end
      end
    end

    def response(event, details)
      "<strong>#{event}</strong><br>#{details}"
    end
  end
end

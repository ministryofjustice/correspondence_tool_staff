require 'rails_helper'

RSpec.describe CaseTransitionDecorator, type: :model do

  let(:dacu) { create :team_dacu }
  let(:dacu_user) { create :manager, managing_teams: [dacu], full_name: 'David Attenborough' }
  let(:laa) { create :business_unit, name: 'Legal Aid Agency' }
  let(:laa_user) { create :responder, responding_teams: [laa], full_name: 'Larry Adler' }

  let(:ct) do
    create(:case_transition_assign_responder,
           acting_user: dacu_user,
           acting_team: dacu,
           target_team: laa,
           created_at: Time.utc(2017, 4, 10, 13, 22, 44)).decorate
  end

  let(:winter_ct) do
    create(:case_transition_assign_responder,
           acting_user: dacu_user,
           acting_team: dacu,
           target_team: laa,
           created_at: Time.utc(2017, 1, 10, 13, 22, 44)).decorate
  end



  describe '#action_date' do
    context 'winter' do
      it 'displays the time in UTC' do
        Timecop.freeze Date.new(2017, 2, 1) do
          expect(winter_ct.action_date).to eq '10 Jan 2017<br>13:22'
        end
      end
    end

    context 'summer' do
      it 'formats the creation date taking BST into account' do
        expect(ct.action_date).to eq '10 Apr 2017<br>14:22'
      end
    end
  end

  describe '#user_name' do
    it 'returns full name of assigning user' do
      expect(ct.user_name).to eq 'David Attenborough'
    end
  end

  describe '#user_team' do
    it 'returns full team name of user' do
      expect(ct.user_team).to eq dacu.name
    end
  end

  describe '#event_and_detail' do
    context 'assign responder' do
      it 'returns team name to which it has been assigned' do
        event = 'Assign responder'
        details = 'Assigned to Legal Aid Agency'
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    context 'accept_responder_assignment' do
      it 'returns expected text' do
        ct = create(:case_transition_accept_responder_assignment).decorate
        event = 'Accepted by Business unit'
        details = ''
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    context 'reject_responder_assignment' do
      it 'returns the reason for rejection' do
        ct = create(:case_transition_reject_responder_assignment, user: laa_user, message: 'Not LAA matter').decorate
        event = 'Rejected by Business unit'
        details = 'Not LAA matter'
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    context 'add_responses' do
      it 'returns number of files uploaded' do
        ct = create(:case_transition_add_responses).decorate
        event = 'Response uploaded'
        details = ''
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    context 'respond' do
      it 'returns marked as reponded' do
        ct = create(:case_transition_respond).decorate
        event = 'Response sent to requester'
        details = ''
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    context 'remove_response' do
      it 'returns name of event' do
        ct = create(:case_transition_remove_response).decorate
        event = 'File removed'
        details = ''
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    context 'add_response_to_flagged_case' do
      it 'returns number of files and description of who its with' do
        ct = create(:case_transition_pending_dacu_clearance).decorate
        event = 'Response uploaded'
        details = ''
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    context 'reassign_user' do
      it 'returns name of event' do
        ct = create(:case_transition_reassign_user).decorate
        action_user = User.find(ct.acting_user_id)
        target_user = User.find(ct.target_user_id)
        event = "Reassign user"
        details = "#{action_user.full_name} re-assigned this case to <strong>#{target_user.full_name}</strong>"
        expect(ct.event_and_detail).to eq response(event, details)
      end

    end

    def response(e, d)
      "<strong>#{e}</strong><br>#{d}"
    end

  end
end

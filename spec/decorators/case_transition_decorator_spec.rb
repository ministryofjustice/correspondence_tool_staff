require 'rails_helper'

RSpec.describe CaseTransitionDecorator, type: :model do

  let(:dacu) { create :team, name: 'DACU' }
  let(:dacu_user) { create :manager, managing_teams: [dacu], full_name: 'David Attenborough' }
  let(:laa) { create :team, name: 'Legal Aid Agency' }
  let(:laa_user) { create :responder, responding_teams: [laa], full_name: 'Larry Adler' }

  let(:ct) do
    create(:case_transition_assign_responder,
           user: dacu_user,
           managing_team: dacu,
           responding_team: laa,
           created_at: Time.utc(2017, 4, 10, 13, 22, 44)).decorate
  end



  describe '#action_date' do
    it 'formats the creation date' do
      expect(ct.action_date).to eq '10 Apr 2017<br>13:22'
    end
  end

  describe '#user_name' do
    it 'returns full name of assigning user' do
      expect(ct.user_name).to eq 'David Attenborough'
    end
  end

  describe '#event_and_detail' do
    context 'assign reponder' do
      it 'returns team name to which it has been assigned' do
        event = 'Assign responder'
        details = 'Assigned to Legal Aid Agency'
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    context 'accept_responder_assignment' do
      it 'returns expected text' do
        ct = create(:case_transition_accept_responder_assignment).decorate
        event = 'Accept responder assignment'
        details = 'Accepted for response'
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    context 'reject_responder_assignment' do
      it 'returns the reason for rejection' do
        ct = create(:case_transition_reject_responder_assignment, user: laa_user, message: 'Not LAA matter').decorate
        event = 'Reject responder assignment'
        details = 'Not LAA matter'
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    context 'add_responses' do
      it 'returns number of files uploaded' do
        ct = create(:case_transition_add_responses).decorate
        event = 'Add responses'
        details = '2 files added'
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    context 'respond' do
      it 'returns marked as reponded' do
        ct = create(:case_transition_respond).decorate
        event = 'Respond'
        details = 'Marked as responded'
        expect(ct.event_and_detail).to eq response(event, details)
      end
    end

    context 'remove_response' do
      it 'returns name of event' do
        ct = create(:case_transition_remove_response).decorate
        expect(ct.event_and_detail).to eq '<strong>Remove response</strong><br>'
      end
    end

    context 'pending_dacu_clearance' do
      it 'returns number of files and description of who its with' do
        ct = create(:case_transition_pending_dacu_clearance).decorate
        expect(ct.event_and_detail).to eq '<strong>Add response to flagged case</strong><br>2 files added<br/>Case is now Pending clearance with DACU disclosure team'
      end
    end

    def response(e, d)
      "<strong>#{e}</strong><br>#{d}"
    end

  end
end

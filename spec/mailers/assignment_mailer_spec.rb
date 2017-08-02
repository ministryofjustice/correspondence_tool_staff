require 'rails_helper'

RSpec.describe AssignmentMailer, type: :mailer do
  describe 'new_assignment' do
    let(:assigned_case) { create :assigned_case,
                                 name: 'Fyodor Ognievich Ilichion',
                                 received_date: 10.business_days.ago,
                                 subject: 'The anatomy of man' }
    let(:assignment) { assigned_case.responder_assignment }
    let(:responding_team) { assignment.team }
    let(:mail) { described_class.new_assignment(assignment) }

    it 'sets the template' do
      expect(mail.govuk_notify_template)
        .to eq '6f4d8e34-96cb-482c-9428-a5c1d5efa519'
    end

    it 'personalises the email' do
      allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
      expect(mail.govuk_notify_personalisation)
        .to eq({
                 email_subject:
                   "#{assigned_case.number} - FOI - The anatomy of man - To be accepted",
                 team_name: assignment.team.name,
                 case_current_state: 'to be accepted',
                 case_number: assigned_case.number,
                 case_abbr: 'FOI',
                 case_name: 'Fyodor Ognievich Ilichion',
                 case_received_date: 10.business_days.ago.to_date,
                 case_subject: 'The anatomy of man',
                 case_link: edit_case_assignment_url(assigned_case.id, assignment.id)
               })
    end

    it 'sets the To address of the email' do
      expect(mail.to).to include responding_team.email
    end

    context 'team does not have a group email address' do
      it 'sends the notification to each user individually' do
        responding_team.email = nil
        expect(mail.to).to match_array responding_team.responders.map(&:email)
      end
    end
  end
end

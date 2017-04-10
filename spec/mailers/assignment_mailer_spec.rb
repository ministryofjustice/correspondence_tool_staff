require 'rails_helper'

RSpec.describe AssignmentMailer, type: :mailer do
  describe 'new_assignment' do

    let(:assignment) { create :assignment, case: create(:case, received_date: Date.new(2017, 4, 5), subject: 'The anatomy of man') }
    let(:mail) { described_class.new_assignment(assignment).deliver_now }

    it 'renders the subject' do
      allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
      expect(mail.subject).to eq('170405333 - FOI - The anatomy of man - Allocation')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([assignment.team.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['noreply@digital.justice.gov.uk'])
    end

    it 'assigns @assignment.team.name' do
      expect(mail.body.encoded).to match("For attention of: #{assignment.team.name} team,")
    end
  end
end

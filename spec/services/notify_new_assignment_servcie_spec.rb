require 'rails_helper'

describe NotifyNewAssignmentService do

  let(:team_with_email)     { create :business_unit, email: 'bu1@moj.com' }
  let(:team_without_email)  { create :business_unit, email: nil }
  let(:assignment)          { double Assignment }
  let(:mailer)              { double ActionNotificationsMailer }


  describe '.run' do
    context 'team has an email' do
      it 'sends one mail to the team email' do
        expect(ActionNotificationsMailer).to receive(:new_assignment).with(assignment, 'bu1@moj.com').and_return(mailer)
        expect(mailer).to receive(:deliver_later).exactly(1)
        NotifyNewAssignmentService.new(team: team_with_email, assignment: assignment).run
      end
    end

    context 'team has  no email' do

      before(:each) do
        create :responder, email: 'r1@moj.com', responding_teams: [team_without_email]
        create :responder, email: 'r2@moj.com', responding_teams: [team_without_email]
      end
      it 'sends an email to each of the responders' do
        expect(ActionNotificationsMailer).to receive(:new_assignment).with(assignment, 'r1@moj.com').and_return(mailer)
        expect(ActionNotificationsMailer).to receive(:new_assignment).with(assignment, 'r2@moj.com').and_return(mailer)
        expect(mailer).to receive(:deliver_later).exactly(2)
        NotifyNewAssignmentService.new(team: team_without_email, assignment: assignment).run
      end
    end
  end

end

require "rails_helper"

describe NotifyNewAssignmentService do
  let(:team_with_email)     { create :business_unit, email: "bu1@moj.com" }
  let(:team_without_email)  { create :business_unit, email: nil }
  let(:assignment)          { instance_double Assignment }
  let(:mailer)              { double ActionNotificationsMailer } # rubocop:disable RSpec/VerifiedDoubles

  describe ".run" do
    context "when team has an email" do
      it "sends one mail to the team email" do
        allow(ActionNotificationsMailer).to receive(:new_assignment).with(assignment, "bu1@moj.com").and_return(mailer)
        expect(mailer).to receive(:deliver_later).exactly(1)
        described_class.new(team: team_with_email, assignment:).run
      end
    end

    context "when team has  no email" do
      before do
        create :responder, email: "r1@moj.com", responding_teams: [team_without_email]
        create :responder, email: "r2@moj.com", responding_teams: [team_without_email]
      end

      it "sends an email to each of the responders" do
        allow(ActionNotificationsMailer).to receive(:new_assignment).with(assignment, "r1@moj.com").and_return(mailer)
        allow(ActionNotificationsMailer).to receive(:new_assignment).with(assignment, "r2@moj.com").and_return(mailer)
        expect(mailer).to receive(:deliver_later).exactly(2)
        described_class.new(team: team_without_email, assignment:).run
      end
    end
  end
end

require "rails_helper"

RSpec.describe DeviseMailer, type: :mailer do
  describe "#reset_password_instructions" do
    let(:user) { create :user, full_name: "Someone" }
    let(:mail) { described_class.reset_password_instructions user, "nEAanath7ath7at8aWF" }

    it "sets the template" do
      expect(mail.govuk_notify_template)
        .to eq "705029c9-d7e4-47a6-a963-944cb6d6b09c"
    end

    it "personalises the email" do
      expect(mail.govuk_notify_personalisation)
        .to eq({
          email_subject: "Password reset",
          user_full_name: "Someone",
          edit_password_url:
                   "http://localhost:5000/users/password/edit?reset_password_token=nEAanath7ath7at8aWF",
        })
    end

    it "sets the To address of the email" do
      expect(mail.to).to include user.email
    end
  end

  describe "unlock_instructions" do
    let(:user) { create :user, full_name: "Someone" }
    let(:mail) { described_class.unlock_instructions(user, "nEAanath7ath7at8aWF") }

    it "sets the template" do
      expect(mail.govuk_notify_template)
          .to eq "9910545b-1b46-41d1-a5e3-f8b31ff450c0"
    end

    it "personalises the email" do
      expect(mail.govuk_notify_personalisation)
          .to eq({
            email_subject: "Your CMS user account has been locked",
            user_full_name: "Someone",
            user_unlock_url:
                         "http://localhost:5000/users/unlock?unlock_token=nEAanath7ath7at8aWF",
          })
    end

    it "sets the To address of the email" do
      expect(mail.to).to include user.email
    end
  end
end

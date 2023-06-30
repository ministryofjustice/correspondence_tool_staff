require "rails_helper"

feature "Signing in" do
  let!(:deactivated_user) { create :deactivated_user }

  scenario "restting password of deactivate users" do
    password_page.load

    password_page.send_reset_instructions(deactivated_user.email)

    expect(login_page.notice.text).to eq "If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes."
  end

  scenario "restting password of user that is not in the database" do
    password_page.load

    password_page.send_reset_instructions(Faker::Internet.email)

    expect(login_page.notice.text).to eq "If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes."
  end
end

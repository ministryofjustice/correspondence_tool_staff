def login_step(user:)
  login_page.load
  login_page.username_field.set user.email
  login_page.password_field.set ENV["TESTSPEC_LOGIN_PASSWORD"]
  login_page.signin.click
  expect(cases_page.user_card.greetings).to have_text user.full_name
end

def logout_step
  login_page.user_card.signout.click
end

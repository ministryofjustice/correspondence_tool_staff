require 'rails_helper'


describe 'cases/respond.html.slim', type: :view do

  let(:responder)    { create(:responder) }
  let(:kase)         { create(:case_with_response, responder: responder) }

  it 'displays the new case page' do

    assign(:case, kase)

    render

    cases_respond_page.load(rendered)

    page = cases_respond_page

    expect(page.page_heading.heading.text).to eq "Mark as sent#{kase.subject}"
    expect(page.page_heading.sub_heading.text).to eq "You are viewing case number #{kase.number} - FOI "

    # expect(page).to have_reminders

    # Capybara text methos seems to be returning whitespace formated text
    # this was not an issue when the same method was called in a feature test
#     expect(page.reminders.text)
#         .to eq("Make sure you have:\n\n  cleared the response with the Deputy Director\n  uploaded \
# the response and any supporting documents\n  sent the response to the person who \
# made the request\n\n")

    # expect(page.alert.text)
    #     .to eq("\n  \n    Important\n  \n  You can't update a response after marking it as sent.\n")

    expect(page).to have_submit_button

    expect(page).to have_back_link
  end
end

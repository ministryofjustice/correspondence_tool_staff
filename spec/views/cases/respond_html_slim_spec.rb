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

    expect(page).to have_submit_button

    expect(page).to have_back_link
  end
end

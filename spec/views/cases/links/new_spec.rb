require "rails_helper"

describe "cases/links/new.html.slim", type: :view do
  let(:kase) { CaseLinkDecorator.decorate create(:case) }

  it "displays the new case page" do
    assign(:case, kase)

    render

    cases_new_case_link_page.load(rendered)

    page = cases_new_case_link_page

    expect(page.page_heading.heading.text).to eq "Link case"
    expect(page.page_heading.sub_heading.text)
      .to eq "You are viewing case number #{kase.number} "

    expect(page.linked_case_number_label.text)
      .to eq "Case number for example 170131001"
    expect(page).to have_linked_case_number_field
    expect(page).to have_submit_button
    expect(page).to have_cancel
  end
end

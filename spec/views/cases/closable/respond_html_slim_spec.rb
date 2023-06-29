require "rails_helper"

describe "cases/closable/respond.html.slim", type: :view do
  let(:foi_case)         { build_stubbed(:case_with_response).decorate }
  let(:ico_case)         { build_stubbed(:approved_ico_foi_case).decorate }

  it "displays the new response page for FOI" do
    assign(:case, foi_case)

    render

    cases_respond_page.load(rendered)

    page = cases_respond_page

    expect(page.page_heading.heading.text).to eq "Mark as sent#{foi_case.subject}"
    expect(page.page_heading.sub_heading.text).to eq "You are viewing case number #{foi_case.number} - FOI "

    expect(page).to have_foi_task_reminder

    expect(page).to have_submit_button

    expect(page).to have_back_link
  end

  it "displays the new response page for ICO" do
    assign(:case, ico_case)

    render

    cases_respond_page.load(rendered)

    page = cases_respond_page

    expect(page.page_heading.heading.text).to eq "Mark as sent#{ico_case.subject}"
    expect(page.page_heading.sub_heading.text).to eq "You are viewing case number #{ico_case.number} - ICO appeal (FOI) "

    expect(page).to have_no_foi_task_reminder

    expect(page).to have_submit_button

    expect(page).to have_back_link
  end
end

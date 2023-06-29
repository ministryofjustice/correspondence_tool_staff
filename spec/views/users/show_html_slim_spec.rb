require "rails_helper"

describe "users/show.html.slim", type: :view do
  let(:responder) { find_or_create :foi_responder }
  let(:kase_1)    { create :accepted_case, created_at: 2.days.ago }
  let(:kase_2)    { create :closed_case, created_at: 1.day.ago }
  let(:kases)     do
    Case::Base.where(id: [kase_1.id, kase_2.id]).order(created_at: :asc).page(1).decorate
  end

  before do
    assign(:user, responder)
    assign(:cases, kases)
    render
    users_show_page.load(rendered)
  end

  it "has the correct page heading" do
    expect(users_show_page.page_heading.heading).to have_text("foi responding user")
    expect(users_show_page.page_heading.sub_heading).to have_text("Open cases")
  end

  it "has download as csv link" do
    expect(users_show_page).to have_download_cases_link
  end

  it "has two cases on the page" do
    expect(users_show_page.case_list.count).to eq 2
  end

  it "has correct data in first case row" do
    row = users_show_page.case_list.first
    expect(row.number).to have_text(kase_1.number)
    expect(row.type).to have_text "FOI"
    expect(row.request_detail).to have_text kase_1.subject
    expect(row.external_deadline).to have_text I18n.l(kase_1.external_deadline)
    expect(row.status).to have_text "Draft in progress"
  end

  it "has correct data in last case row" do
    row = users_show_page.case_list.last
    expect(row.number).to have_text(kase_2.number)
    expect(row.type).to have_text "FOI"
    expect(row.request_detail).to have_text kase_2.subject
    expect(row.external_deadline).to have_text I18n.l(kase_2.external_deadline)
    expect(row.status).to have_text "Closed"
  end
end

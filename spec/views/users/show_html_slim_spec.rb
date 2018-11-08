require 'rails_helper'

describe 'users/show.html.slim', type: :view do
  let(:responder) { create :responder, full_name: 'Larry Adler' }
  let(:kase_1)    { create :accepted_case }
  let(:kase_2)    { create :closed_case }
  let(:kases)     { Case::Base.where(id: [kase_1.id, kase_2.id]).page(1).decorate }

  before(:each) do
    assign(:user, responder)
    assign(:cases, kases)
    render
  end

  it 'has the correct page heading' do
    users_show_page.load(rendered)
    expect(users_show_page.page_heading.heading).to have_text('Larry Adler')
    expect(users_show_page.page_heading.sub_heading).to have_text('Open cases')
  end

  it 'has download as csv link' do
    users_show_page.load(rendered)
    expect(users_show_page).to have_download_cases_link
  end

  it 'has two cases on the page' do
    users_show_page.load(rendered)
    expect(users_show_page.case_list.count).to eq 2
  end

  it 'has correct data in case rows' do
    users_show_page.load(rendered)

    row = users_show_page.case_list.first
    expect(row.number).to have_text(kase_1.number)
    expect(row.type).to have_text 'FOI'
    expect(row.request_detail).to have_text kase_1.subject
    expect(row.external_deadline).to have_text I18n.l(kase_1.external_deadline)
    expect(row.status).to have_text 'Draft in progress'

    row = users_show_page.case_list.last
    expect(row.number).to have_text(kase_2.number)
    expect(row.type).to have_text 'FOI'
    expect(row.request_detail).to have_text kase_2.subject
    expect(row.external_deadline).to have_text I18n.l(kase_2.external_deadline)
    expect(row.status).to have_text 'Case closed'
  end
end



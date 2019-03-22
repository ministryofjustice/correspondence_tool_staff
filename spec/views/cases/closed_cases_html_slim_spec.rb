require 'rails_helper'

describe 'cases/closed_cases.html.slim' do
  let!(:case_1) { create :closed_case, received_date: 20.business_days.ago }
  let!(:case_2) { create :closed_case }

  it 'displays all the cases' do
    cases = Case::Base.closed.most_recent_first.page.decorate
    assign(:cases, cases)

    render

    closed_cases_page.load(rendered)
    page = closed_cases_page

    expect(page.page_heading.heading.text).to eq 'Closed cases'
    expect(page.page_heading).to have_no_sub_heading

    expect(page.closed_case_report.table_body.closed_case_rows.size).to eq 2

    row = page.closed_case_report.table_body.closed_case_rows.first
    expect(row.case_number.text).to eq "Link to case #{case_1.number}"
    expect(row.subject_name.name.text).to eq case_1.name
    expect(row.subject_name.subject.text).to eq case_1.subject

    row = page.closed_case_report.table_body.closed_case_rows.last
    expect(row.case_number.text).to eq "Link to case #{case_2.number}"
    expect(row.subject_name.name.text).to eq case_2.name
    expect(row.subject_name.subject.text).to eq case_2.subject

    expect(page).to have_download_deleted_cases_link
  end

  describe 'pagination' do
    before do
      allow(view).to receive(:policy).and_return(spy('Pundit::Policy'))
    end

    it 'renders the paginator' do
      assign(:cases, Case::Base.none.page.decorate)
      render
      expect(response).to have_rendered('kaminari/_paginator')
    end
  end
end

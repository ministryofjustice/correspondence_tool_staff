require 'rails_helper'

describe 'cases/closed_cases.html.slim' do

  it 'displays all the cases' do
    case_1 = double CaseDecorator, name: 'Joe Smith', subject: 'Prison Reform', id: 123, number: '16-12345'
    case_2 = double CaseDecorator, name: 'Jane Doe', subject: 'Court Reform', id: 567, number: '17-00022'
    assign(:cases, [case_1, case_2])

    render

    closed_cases_page.load(rendered)
    page = closed_cases_page

    expect(page.page_heading.heading.text).to eq 'Closed cases'
    expect(page.page_heading).to have_no_sub_heading

    expect(page.closed_case_report.table_body.closed_case_rows.size).to eq 2

    row = page.closed_case_report.table_body.closed_case_rows.first
    expect(row.case_number.text).to eq 'Link to case 16-12345'
    expect(row.subject_name.name.text).to eq 'Joe Smith'
    expect(row.subject_name.subject.text).to eq 'Prison Reform'

    row = page.closed_case_report.table_body.closed_case_rows.last
    expect(row.case_number.text).to eq 'Link to case 17-00022'
    expect(row.subject_name.name.text).to eq 'Jane Doe'
    expect(row.subject_name.subject.text).to eq 'Court Reform'
  end
end

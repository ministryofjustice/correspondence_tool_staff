require 'rails_helper'

describe 'cases/index.html.slim', type: :view do

  it 'displays the cases given it' do
    case1 = double CaseDecorator,
                   id: 123,
                   name: 'Joe Smith',
                   subject: 'Prison Reform',
                   number: '16-12345',
                   external_deadline: DateTime.now + 10.days,
                   current_state: 'drafting',
                   who_its_with: 'HR'
    case2 = double CaseDecorator,
                   id: 567,
                   name: 'Jane Doe',
                   subject: 'Court Reform',
                   number: '17-00022',
                   external_deadline: DateTime.now + 11.days,
                   current_state: 'awaiting_responder',
                   who_its_with: 'LAA'
    assign(:cases, [case1, case2])

    policy = double('Pundit::Policy', can_add_case?: false)
    allow(view).to receive(:policy).with(:case).and_return(policy)

    render
    cases_page.load(rendered)

    expect(cases_page.case_list[0].number.text).to eq 'Link to case 16-12345'
    expect(cases_page.case_list[0].name.text).to eq 'Joe Smith'
    expect(cases_page.case_list[0].subject.text).to eq 'Prison Reform'
    expect(cases_page.case_list[0].external_deadline.text)
      .to eq((DateTime.now + 10.days).strftime('%e %b %Y'))
    expect(cases_page.case_list[0].status.text).to eq 'Response'
    expect(cases_page.case_list[0].who_its_with.text).to eq 'HR'

    expect(cases_page.case_list[1].number.text).to eq 'Link to case 17-00022'
    expect(cases_page.case_list[1].name.text).to eq 'Jane Doe'
    expect(cases_page.case_list[1].subject.text).to eq 'Court Reform'
    expect(cases_page.case_list[1].external_deadline.text)
      .to eq((DateTime.now + 11.days).strftime('%e %b %Y'))
    expect(cases_page.case_list[1].status.text).to eq 'Acceptance'
    expect(cases_page.case_list[1].who_its_with.text).to eq 'LAA'
  end
end

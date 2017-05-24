require 'rails_helper'

def allow_case_policy(policy_name)
  policy = double('Pundit::Policy', policy_name => true)
  allow(view).to receive(:policy).with(:case).and_return(policy)
end

def disallow_case_policy(policy_name)
  policy = double('Pundit::Policy', policy_name => false)
  allow(view).to receive(:policy).with(:case).and_return(policy)
end

describe 'cases/index.html.slim', type: :view do

  it 'displays the cases given it' do

    case1 = double CaseDecorator,
                   id: 123,
                   name: 'Joe Smith',
                   subject: 'Prison Reform',
                   number: '16-12345',
                   internal_deadline: (DateTime.now + 5.days).strftime('%e %b %Y'),
                   external_deadline: (DateTime.now + 10.days).strftime('%e %b %Y'),
                   current_state: 'drafting',
                   who_its_with: 'HR'
    case2 = double CaseDecorator,
                   id: 567,
                   name: 'Jane Doe',
                   subject: 'Court Reform',
                   number: '17-00022',
                   internal_deadline: (DateTime.now + 5.days).strftime('%e %b %Y'),
                   external_deadline: (DateTime.now + 11.days).strftime('%e %b %Y'),
                   current_state: 'awaiting_responder',
                   who_its_with: 'LAA'
    assign(:cases, [case1, case2])

    disallow_case_policy :can_add_case?

    render
    cases_page.load(rendered)

    expect(cases_page.case_list[0].number.text).to eq 'Link to case 16-12345'
    expect(cases_page.case_list[0].request_detail.text).to eq 'Prison ReformJoe Smith'
    expect(cases_page.case_list[0].draft_deadline.text).to eq((Date.today + 5.days).strftime('%e %b %Y'))
    expect(cases_page.case_list[0].external_deadline.text).to eq((Date.today + 10.days).strftime('%e %b %Y'))
    expect(cases_page.case_list[0].status.text).to eq 'Draft in progress'
    expect(cases_page.case_list[0].who_its_with.text).to eq 'HR'

    expect(cases_page.case_list[1].number.text).to eq 'Link to case 17-00022'
    expect(cases_page.case_list[1].request_detail.text).to eq 'Court ReformJane Doe'
    expect(cases_page.case_list[1].draft_deadline.text).to eq((Date.today + 5.days).strftime('%e %b %Y'))
    expect(cases_page.case_list[1].external_deadline.text).to eq((Date.today + 11.days).strftime('%e %b %Y'))
    expect(cases_page.case_list[1].status.text).to eq 'To be accepted'
    expect(cases_page.case_list[1].who_its_with.text).to eq 'LAA'
  end

  describe 'add case button' do
    it 'is displayed when the user can add cases' do
      assign(:cases, [])

      allow_case_policy :can_add_case?

      render
      cases_page.load(rendered)

      expect(cases_page).to have_new_case_button
    end

    it 'is not displayed when the user cannot add cases' do
      assign(:cases, [])

      disallow_case_policy :can_add_case?

      render
      cases_page.load(rendered)

      expect(cases_page).not_to have_new_case_button
    end
  end
end

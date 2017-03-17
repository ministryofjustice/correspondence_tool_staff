require 'rails_helper'

feature 'listing cases on the system' do
  given(:foi_category) { create(:category) }
  given(:assigned_case) do
    create(
      :assigned_case,
      name: 'Freddie FOI Assigned',
      email: 'freddie.foi@testing.digital.justice.gov.uk',
      subject: 'test assigned FOI subject',
      message: 'viewing assigned foi details test message',
      category: foi_category
    )
  end

  given(:unassigned_case) do
    create(
      :case,
      name: 'Freddie FOI Unassigned',
      email: 'freddie.foi@testing.digital.justice.gov.uk',
      subject: 'test unassigned FOI subject',
      message: 'viewing unassigned foi details test message',
      category: foi_category
    )
  end

  given(:accepted_case) do
    create(:accepted_case,
           name: 'Freddie FOI Accepted',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'test accepted FOI subject',
           message: 'viewing accepted foi details test message',
           category: foi_category,
           drafter: assigned_case.drafter
    )
  end

  given(:case_with_response) do
    create(:case_with_response,
           name: 'Freddie FOI Responded',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'test case with response FOI subject',
           message: 'viewing case with response foi details test message',
           category: foi_category,
           drafter: assigned_case.drafter
    )
  end

  given(:responded_case) do
    create(:responded_case,
           name: 'Freddie FOI Responded',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'test responded FOI subject',
           message: 'viewing responded foi details test message',
           category: foi_category
    )
  end

  background do
    # Create our cases
    unassigned_case
    assigned_case
    accepted_case
    case_with_response
    responded_case
  end

  scenario 'for assigners - shows all cases' do
    login_as create(:assigner)
    visit '/'
    expect(cases_page.case_list.count).to eq 5

    unassigned_case_row = cases_page.case_list.first
    expect(unassigned_case_row.name.text).to     eq 'Freddie FOI Unassigned'
    expect(unassigned_case_row.subject.text).to  eq 'test unassigned FOI subject'
    expect(unassigned_case_row.external_deadline.text)
        .to have_content(unassigned_case.external_deadline.strftime('%e %b %Y'))
    expect(unassigned_case_row.number)
        .to have_link("#{unassigned_case.number}", href: case_path(unassigned_case.id))
    expect(unassigned_case_row.status.text).to eq 'Allocation'
    expect(unassigned_case_row.who_its_with.text).to eq 'DACU'


    assigned_case_row = cases_page.case_list.second
    expect(assigned_case_row.name.text).to     eq 'Freddie FOI Assigned'
    expect(assigned_case_row.subject.text).to  eq 'test assigned FOI subject'
    expect(assigned_case_row.external_deadline.text)
        .to have_content(assigned_case.external_deadline.strftime('%e %b %Y'))
    expect(assigned_case_row.number)
        .to have_link("#{assigned_case.number}", href: case_path(assigned_case.id))
    expect(assigned_case_row.status.text).to eq 'Acceptance'
    expect(assigned_case_row.who_its_with.text).to eq assigned_case.drafter.full_name


    accepted_case_row = cases_page.case_list.third
    expect(accepted_case_row.name.text).to     eq 'Freddie FOI Accepted'
    expect(accepted_case_row.subject.text).to  eq 'test accepted FOI subject'
    expect(accepted_case_row.external_deadline.text)
        .to have_content(accepted_case.external_deadline.strftime('%e %b %Y'))
    expect(accepted_case_row.number)
        .to have_link("#{accepted_case.number}", href: case_path(accepted_case.id))
    expect(accepted_case_row.status.text).to eq 'Response'
    expect(accepted_case_row.who_its_with.text).to eq accepted_case.drafter.full_name


    case_with_response_row = cases_page.case_list.fourth
    expect(case_with_response_row.name.text).to     eq 'Freddie FOI Responded'
    expect(case_with_response_row.subject.text).to  eq 'test case with response FOI subject'
    expect(case_with_response_row.external_deadline.text)
        .to have_content(case_with_response.external_deadline.strftime('%e %b %Y'))
    expect(case_with_response_row.number)
        .to have_link("#{case_with_response.number}", href: case_path(case_with_response.id))
    expect(case_with_response_row.status.text).to eq 'Awaiting Dispatch'
    expect(case_with_response_row.who_its_with.text).to eq case_with_response.drafter.full_name


    responded_case_row = cases_page.case_list.last
    expect(responded_case_row.name.text).to     eq 'Freddie FOI Responded'
    expect(responded_case_row.subject.text).to  eq 'test responded FOI subject'
    expect(responded_case_row.external_deadline.text)
        .to have_content(responded_case.external_deadline.strftime('%e %b %Y'))
    expect(responded_case_row.number)
        .to have_link("#{responded_case.number}", href: case_path(responded_case.id))
    expect(responded_case_row.status.text).to eq 'Closure'
    expect(responded_case_row.who_its_with.text).to eq responded_case.drafter.full_name

  end

  scenario 'For drafters - shows only their (open) assigned cases' do
    login_as assigned_case.drafter
    visit '/'
    expect(cases_page.case_list.count).to eq 3

    assigned_case_row = cases_page.case_list.first
    expect(assigned_case_row.name.text).to     eq 'Freddie FOI Assigned'
    expect(assigned_case_row.subject.text).to  eq 'test assigned FOI subject'
    expect(assigned_case_row.external_deadline.text)
        .to have_content(assigned_case.external_deadline.strftime('%e %b %Y'))
    expect(assigned_case_row.number)
        .to have_link("#{assigned_case.number}",
                      href: case_path(assigned_case))
    expect(assigned_case_row.status.text).to eq 'Acceptance'
    expect(assigned_case_row.who_its_with.text).to eq assigned_case.drafter.full_name


    accepted_case_row = cases_page.case_list.second
    expect(accepted_case_row.name.text).to     eq 'Freddie FOI Accepted'
    expect(accepted_case_row.subject.text).to  eq 'test accepted FOI subject'
    expect(accepted_case_row.external_deadline.text)
        .to have_content(accepted_case.external_deadline.strftime('%e %b %Y'))
    expect(accepted_case_row.number)
        .to have_link("#{accepted_case.number}",
                      href: case_path(accepted_case))
    expect(accepted_case_row.status.text).to eq 'Response'
    expect(accepted_case_row.who_its_with.text).to eq accepted_case.drafter.full_name


    case_with_response_row = cases_page.case_list.third
    expect(case_with_response_row.name.text).to     eq 'Freddie FOI Responded'
    expect(case_with_response_row.subject.text).to  eq 'test case with response FOI subject'
    expect(case_with_response_row.external_deadline.text)
        .to have_content(case_with_response.external_deadline.strftime('%e %b %Y'))
    expect(case_with_response_row.number)
        .to have_link("#{case_with_response.number}", href: case_path(case_with_response.id))
    expect(case_with_response_row.status.text).to eq 'Awaiting Dispatch'
    expect(case_with_response_row.who_its_with.text).to eq case_with_response.drafter.full_name
  end

end

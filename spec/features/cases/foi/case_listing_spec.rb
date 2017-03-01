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

  background do
    # Create our cases
    unassigned_case
    assigned_case
    accepted_case
  end

  scenario 'for assigners - shows all cases' do
    login_as create(:user, roles: ['assigner'])
    visit '/'
    expect(cases_page.case_list.count).to eq 3

    unassigned_case_row = cases_page.case_list.first
    expect(unassigned_case_row.name.text).to     eq 'Freddie FOI Unassigned'
    expect(unassigned_case_row.subject.text).to  eq 'test unassigned FOI subject'
    expect(unassigned_case_row.external_deadline.text)
        .to have_content(unassigned_case.external_deadline.strftime('%e %b %Y'))
    expect(unassigned_case_row.number)
        .to have_link("#{unassigned_case.number}", href: case_path(unassigned_case.id))
    expect(unassigned_case_row.status.text).to eq 'Waiting to be assigned'
    expect(unassigned_case_row.who_its_with.text).to eq 'DACU'


    assigned_case_row = cases_page.case_list.second
    expect(assigned_case_row.name.text).to     eq 'Freddie FOI Assigned'
    expect(assigned_case_row.subject.text).to  eq 'test assigned FOI subject'
    expect(assigned_case_row.external_deadline.text)
        .to have_content(assigned_case.external_deadline.strftime('%e %b %Y'))
    expect(assigned_case_row.number)
        .to have_link("#{assigned_case.number}", href: case_path(assigned_case.id))
    expect(assigned_case_row.status.text).to eq 'Waiting to be accepted'
    expect(assigned_case_row.who_its_with.text).to eq assigned_case.drafter.full_name


    accepted_case_row = cases_page.case_list.last
    expect(accepted_case_row.name.text).to     eq 'Freddie FOI Accepted'
    expect(accepted_case_row.subject.text).to  eq 'test accepted FOI subject'
    expect(accepted_case_row.external_deadline.text)
        .to have_content(accepted_case.external_deadline.strftime('%e %b %Y'))
    expect(accepted_case_row.number)
        .to have_link("#{accepted_case.number}", href: case_path(accepted_case.id))
    expect(accepted_case_row.status.text).to eq 'Waiting for draft response'
    expect(accepted_case_row.who_its_with.text).to eq accepted_case.drafter.full_name


  end

  scenario 'For drafters - shows only their (open) assigned cases' do
    login_as assigned_case.drafter
    visit '/'
    expect(cases_page.case_list.count).to eq 2

    assigned_case_row = cases_page.case_list.first
    expect(assigned_case_row.name.text).to     eq 'Freddie FOI Assigned'
    expect(assigned_case_row.subject.text).to  eq 'test assigned FOI subject'
    expect(assigned_case_row.external_deadline.text)
        .to have_content(assigned_case.external_deadline.strftime('%e %b %Y'))
    expect(assigned_case_row.number)
        .to have_link("#{assigned_case.number}",
                      href: edit_case_assignment_path(assigned_case,
                                                      assigned_case.assignments.last.id))
    expect(assigned_case_row.status.text).to eq 'Waiting to be accepted'
    expect(assigned_case_row.who_its_with.text).to eq assigned_case.drafter.full_name


    accepted_case_row = cases_page.case_list.last
    expect(accepted_case_row.name.text).to     eq 'Freddie FOI Accepted'
    expect(accepted_case_row.subject.text).to  eq 'test accepted FOI subject'
    expect(accepted_case_row.external_deadline.text)
        .to have_content(accepted_case.external_deadline.strftime('%e %b %Y'))
    expect(accepted_case_row.number)
        .to have_link("#{accepted_case.number}",
                      href: case_path(accepted_case))
    expect(accepted_case_row.status.text).to eq 'Waiting for draft response'
    expect(accepted_case_row.who_its_with.text).to eq accepted_case.drafter.full_name
  end

end

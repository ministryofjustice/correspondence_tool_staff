require 'rails_helper'

describe 'assignments/new.html.slim', type: :view do
  let(:unassigned_case)   { create :case }
  let(:business_unit_1)   { create :responding_team}
  let(:business_unit_2)   { create :responding_team}
  let(:business_unit_3)   { create :responding_team}

  it 'displays the new assignment page for a new case' do

    assign(:case, unassigned_case)
    assign(:assignment, unassigned_case.assignments.new)
    flash[:notice] = true
    assign(:creating_case, true)

    render

    assignments_new_page.load(rendered)

    page = assignments_new_page

    expect(page.page_heading.heading.text).to eq "Assign case"
    expect(page.page_heading.sub_heading.text)
        .to eq "Create case "

    expect(page.business_groups).to have_group
    expect(page.business_groups).to have_all_groups

    expect(page).to have_no_assign_to
  end

  context 'User has selected a specific business group or viewing all'  do
    it 'displays the new assignment page with business unites' do

      assign(:case, unassigned_case)
      assign(:assignment, unassigned_case.assignments.new)
      flash[:notice] = true
      assign(:creating_case, true)
      assign(:business_units, [business_unit_1,business_unit_2,business_unit_3])

      render

      assignments_new_page.load(rendered)

      page = assignments_new_page

      expect(page.page_heading.heading.text).to eq "Assign case"
      expect(page.page_heading.sub_heading.text)
          .to eq "Create case "

      expect(page.business_groups).to have_group
      expect(page.business_groups).to have_all_groups

      expect(page.assign_to.team.count).to eq 3

      any_team = page.assign_to.team.first
      expect(any_team.business_unit.text).to eq business_unit_1.name
      expect(any_team.assign_link.text).to eq "Assign to this unit"
      expect(any_team.assign_link[:href]).to eq case_assign_to_responder_team_path(unassigned_case, team_id: business_unit_1.id )
    end
  end
end

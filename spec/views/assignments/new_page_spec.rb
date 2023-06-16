require "rails_helper"

describe "assignments/new.html.slim", type: :view do
  let(:unassigned_case)    { create :case }
  let(:bg)                 { create :business_group }
  let(:dir)                { create :directorate, business_group: bg }
  let!(:business_unit_1)   { create :responding_team, directorate: dir }
  let!(:business_unit_2)   { create :responding_team, directorate: dir }
  let!(:business_unit_3)   { create :responding_team, directorate: dir }

  it "displays the new assignment page for a new case" do
    deactivated_bg = create :business_group, deleted_at: Date.today, name: "[DEACTIVATED] testing"
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
    expect(page).to have_content bg.name
    expect(page).not_to have_content deactivated_bg.name

    expect(page).to have_no_assign_to
  end

  context "User has selected a specific business group or viewing all" do
    it "displays the new assignment page with business units" do
      assign(:case, unassigned_case.decorate)
      assign(:assignment, unassigned_case.assignments.new)
      flash[:notice] = true
      assign(:creating_case, true)
      assign(:business_units, dir.business_units)

      render

      assignments_new_page.load(rendered)

      page = assignments_new_page

      expect(page.page_heading.heading.text).to eq "Assign case"
      expect(page.page_heading.sub_heading.text)
          .to eq "Create case "

      expect(page.business_groups).to have_group
      expect(page.business_groups).to have_all_groups

      expect(page.assign_to.team.count).to eq 3

      dir.business_units.each do |bu|
        page_team = page.assign_to.team.detect { |team| team.business_unit.text == bu.name }

        expect(page_team.areas_covered.map(&:text))
            .to match_array bu.areas.map(&:value)

        expect(page_team.deputy_director.text).to eq bu.team_lead

        expect(page_team.assign_link.text).to eq "Assign to #{bu.name}"
        expect(page_team.assign_link[:href])
            .to eq assign_to_responder_team_case_assignments_path(
              unassigned_case,
              team_id: bu.id,
            )
      end
    end
  end
end

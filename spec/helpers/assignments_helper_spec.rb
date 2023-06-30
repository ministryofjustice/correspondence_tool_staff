require "rails_helper"

# Specs in this file have access to a helper object that includes
# the AssignmentsHelper. For example:
#
# describe AssignmentsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe AssignmentsHelper, type: :helper do
  describe "#page_heading" do
    it "returns the appropriate message when assigning a new case" do
      expect(sub_heading(true))
        .to eq "Create case"
    end

    it "returns the appropriate message when only assigning a case" do
      expect(sub_heading(false))
        .to eq "Existing case"
    end
  end

  describe "#filtered_group_heading" do
    let(:business_group) { create :business_group }

    it "returns the selected groups name as a heading" do
      controller.params[:business_group_id] = business_group.id
      expect(filtered_group_heading(params))
          .to eq "#{business_group.name} business units"
    end

    it 'returns "All group" as a heading' do
      controller.params[:show_all] = true
      expect(filtered_group_heading(params))
          .to eq "All business units"
    end
  end

  describe "#all_option_for_new_case" do
    let(:business_group) { create :business_group }
    let(:unassigned_case) { create :case }

    it "returns a link if the option has not been selected" do
      controller.params[:show_all] = nil
      expect(all_option_for_new_case(unassigned_case, params))
          .to eq "<a class=\"bold-small\" href=\"/cases/#{unassigned_case.id}/assignments/new?show_all=true\">See all business units</a>"
    end

    it "returns plain text if it has been selected" do
      controller.params[:show_all] = true
      expect(all_option_for_new_case(unassigned_case, params))
          .to eq "See all business units"
    end
  end

  describe "#all_option_for_new_team" do
    let(:business_group)   { create :business_group }
    let(:assigned_case)    { create :assigned_case }
    let(:assignment)       { assigned_case.responder_assignment }

    it "returns a link if the option has not been selected" do
      controller.params[:show_all] = nil
      expect(all_option_for_new_team(assigned_case, assignment, params))
        .to eq "<a class=\"bold-small\" href=\"/cases/#{assigned_case.id}/assignments/#{assignment.id}/assign_to_new_team?show_all=true\">See all business units</a>"
    end

    it "returns plain text if it has been selected" do
      controller.params[:show_all] = true
      expect(all_option_for_new_team(assigned_case, assignment, params))
        .to eq "See all business units"
    end
  end

  describe "#business_group_option_for_new_case" do
    let(:business_group) { create :business_group }
    let(:unassigned_case) { create :case }

    it "returns a link if the option has not been selected" do
      controller.params[:business_group_id] = nil
      expect(business_group_option_for_new_case(unassigned_case, business_group, params))
          .to eq "<a href=\"/cases/#{unassigned_case.id}/assignments/new?business_group_id=#{business_group.id}\">#{business_group.name}</a>"
    end

    it "returns plain text if it has been selected" do
      controller.params[:business_group_id] = business_group.id
      expect(business_group_option_for_new_case(unassigned_case, business_group, params))
          .to eq business_group.name
    end
  end

  describe "#business_group_option_for_new_team" do
    let(:business_group)   { create :business_group }
    let(:assigned_case)    { create :assigned_case }
    let(:assignment)       { assigned_case.responder_assignment }

    it "returns a link if the option has not been selected" do
      controller.params[:business_group_id] = nil
      expect(business_group_option_for_new_team(assigned_case, assignment, business_group, params))
        .to eq "<a href=\"/cases/#{assigned_case.id}/assignments/#{assignment.id}/assign_to_new_team?business_group_id=#{business_group.id}\">#{business_group.name}</a>"
    end

    it "returns plain text if it has been selected" do
      controller.params[:business_group_id] = business_group.id
      expect(business_group_option_for_new_team(assigned_case, assignment, business_group, params))
        .to eq business_group.name
    end
  end
end

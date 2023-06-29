module AssignmentsHelper
  def sub_heading(creating_case)
    if creating_case
      t("assignments.new.new_assignment")
    else
      t("assignments.new.assignment")
    end
  end

  def filtered_group_heading(params)
    if params[:business_group_id]
      business_group = BusinessGroup.find(params[:business_group_id])
      "#{business_group.name} business units"
    elsif params[:show_all]
      "All business units"
    end
  end

  def filtered_directorate_heading(params)
    if params[:business_group_id]
      business_group = BusinessGroup.find(params[:business_group_id])
      "#{business_group.name} directorates"
    end
  end

  def all_option_for_new_case(kase, params)
    if params[:show_all]
      "See all business units"
    else
      link_to("See all business units",
              new_case_assignment_path(kase.id, show_all: true),
              class: "bold-small")
    end
  end

  def all_option_for_new_team(kase, assignment, params)
    if params[:show_all]
      "See all business units"
    else
      link_to("See all business units",
              assign_to_new_team_case_assignment_path(kase.id, assignment.id, show_all: true),
              class: "bold-small")
    end
  end

  def business_group_option_for_new_case(kase, business_group, params)
    if business_group.id == params[:business_group_id].to_i
      business_group.name
    else
      link_to(business_group.name,
              new_case_assignment_path(kase.id,
                                       business_group_id: business_group.id))
    end
  end

  def business_group_option_for_new_team(kase, assignment, business_group, params)
    if business_group.id == params[:business_group_id].to_i
      business_group.name
    else
      link_to(business_group.name,
              assign_to_new_team_case_assignment_path(kase.id, assignment.id,
                                                      business_group_id: business_group.id))
    end
  end
end

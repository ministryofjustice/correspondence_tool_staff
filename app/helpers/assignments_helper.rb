module AssignmentsHelper
  def page_heading(creating_case)
    if creating_case
      t('assignments.new.new_assignment_while_creating')
    else
      t('assignments.new.new_assignment')
    end
  end

  def assign_button_text(creating_case)
    if creating_case
      t('button.create_and_assign')
    else
      t('button.assign')
    end
  end
end

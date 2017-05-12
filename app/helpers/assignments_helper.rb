module AssignmentsHelper
  def sub_heading(creating_case)
    if creating_case
      t('assignments.new.new_assignment')
    else
      t('assignments.new.assignment')
    end
  end
end

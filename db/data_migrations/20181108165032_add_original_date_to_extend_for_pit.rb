class AddOriginalDateToExtendForPit < ActiveRecord::DataMigration
  def up
    transitions = CaseTransition.where(event: "extend_for_pit")
    transitions.each do |transition|
      transition.update(original_final_deadline: find_original_final_deadline(transition))
    end
  end

private

  def find_original_final_deadline(transition)
    kase = Case::Base.unscoped.find(transition.case_id)
    if kase.overturned_ico?
      kase.external_deadline
    else
      kase.deadline_calculator.external_deadline
    end
  end
end

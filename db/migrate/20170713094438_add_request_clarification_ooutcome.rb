class AddRequestClarificationOoutcome < ActiveRecord::Migration[5.0]
  def up
    CaseClosure::Outcome.find_or_create_by!(subtype: nil, name: 'Clarification needed - Section 1(3)', abbreviation: 'clarify', sequence_id: 15)
  end

  def down
    CaseClosure::Outcome.where(name: 'Clarification needed - Section 1(3)').first.destroy
  end
end

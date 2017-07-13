class AddRequestClarificationOoutcome < ActiveRecord::Migration[5.0]
  def up
    CaseClosure::Outcome.find_or_create_by!(subtype: nil, name: 'Clarification requested', abbreviation: 'clarify', sequence_id: 40)
  end

  def down
    CaseClosure::Outcome.where(name: 'Clarification requested').first.destroy
  end
end

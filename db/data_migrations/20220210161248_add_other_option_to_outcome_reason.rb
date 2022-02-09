class AddOtherOptionToOutcomeReason < ActiveRecord::DataMigration
  def up
    CaseClosure::OutcomeReason.find_or_create_by!(
      name: 'Other',
      abbreviation: 'other',
      sequence_id: 915)
  end

  def down
    ['other'].each do |abbreviation|
       outcome_reason = CaseClosure::OutcomeReason.find_by(
         abbreviation: abbreviation
       )
       outcome_reason.delete if outcome_reason.nil?
    end
  end
end

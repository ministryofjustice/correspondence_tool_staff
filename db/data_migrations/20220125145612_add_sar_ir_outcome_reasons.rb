class AddSarIrOutcomeReasons < ActiveRecord::DataMigration
  def up
    CaseClosure::OutcomeReason.find_or_create_by!(
      name: "Proper searches not carried out/missing information",
      abbreviation: "missing_info",
      sequence_id: 900,
    )

    CaseClosure::OutcomeReason.find_or_create_by!(
      name: "Incorrect exemption engaged",
      abbreviation: "wrong_exemp",
      sequence_id: 905,
    )

    CaseClosure::OutcomeReason.find_or_create_by!(
      name: "Excessive redaction(s)",
      abbreviation: "excess_redacts",
      sequence_id: 910,
    )
  end

  def down
    %w[missing_info wrong_exemp excess_redacts].each do |abbreviation|
      outcome_reason = CaseClosure::OutcomeReason.find_by(
        abbreviation:,
      )
      outcome_reason.delete if outcome_reason.nil?
    end
  end
end

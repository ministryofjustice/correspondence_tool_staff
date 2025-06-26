class CreateAndPopulateSARTmmClosureReason < ActiveRecord::DataMigration
  def up
    CaseClosure::RefusalReason.find_or_create_by!(subtype: nil, name: "SAR Clarification/Tell Me More", abbreviation: "sartmm", sequence_id: 105)
    tmm_sars = Case::SAR::Standard.where(refusal_reason: CaseClosure::RefusalReason.tmm)
    tmm_sars.each do |kase|
      kase.update(refusal_reason: CaseClosure::RefusalReason.sar_tmm)
    end
  end

  def down
    tmm_sars = Case::SAR::Standard.where(refusal_reason: CaseClosure::RefusalReason.sar_tmm)
    tmm_sars.each do |kase|
      kase.update(refusal_reason: CaseClosure::RefusalReason.tmm)
    end
    CaseClosure::RefusalReason.where(name: "SAR Clarification/Tell Me More").first.destroy!
  end
end

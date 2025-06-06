class ModifyICODeadlineClassSetting < ActiveRecord::DataMigration
  def up
    CorrespondenceType.all.find_each do |ct|
      next unless ct.abbreviation == "ICO"

      ct.update!(
        deadline_calculator_class: "BusinessDays",
        internal_time_limit: 10,
        escalation_time_limit: 3,
      )
    end
  end
end

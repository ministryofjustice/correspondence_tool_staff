class ChangeComplaintTypeDeadlineCalculator < ActiveRecord::DataMigration
  def up
    rec = CorrespondenceType.find_by(abbreviation: "OFFENDER_SAR_COMPLAINT")
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(escalation_time_limit: 3,
                internal_time_limit: 10,
                external_time_limit: 20,
                deadline_calculator_class: "BusinessDays")
  end
end

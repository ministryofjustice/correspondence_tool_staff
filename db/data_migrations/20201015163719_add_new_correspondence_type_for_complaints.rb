class AddNewCorrespondenceTypeForComplaints < ActiveRecord::DataMigration
  def up
    rec = CorrespondenceType.find_by(abbreviation: "OFFENDER_SAR_COMPLAINT")
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: "Offender subject access request complaint",
                abbreviation: "OFFENDER_SAR_COMPLAINT",
                escalation_time_limit: 3,
                internal_time_limit: 10,
                external_time_limit: 1,
                deadline_calculator_class: "CalendarMonths")
  end
end

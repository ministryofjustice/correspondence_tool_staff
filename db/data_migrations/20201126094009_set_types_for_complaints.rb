class SetTypesForComplaints < ActiveRecord::DataMigration
  def up
    kases = Case::Base.offender_sar_complaint.all
    kases.each do |kase|
      kase.update_attribute(:complaint_type, "standard") if kase.complaint_type.blank?
      kase.update_attribute(:complaint_subtype, "missing_data") if kase.complaint_subtype.blank?
      kase.update_attribute(:priority, "normal") if kase.priority.blank?
    end
  end
end

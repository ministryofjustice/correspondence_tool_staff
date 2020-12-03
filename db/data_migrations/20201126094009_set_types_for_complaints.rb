class SetTypesForComplaints < ActiveRecord::DataMigration
  def up
    kases = Case::Base.offender_sar_complaint.all
    kases.each do |kase|
      kase.update_attribute(:complaint_type, 'standard') unless kase.complaint_type.present?
      kase.update_attribute(:complaint_subtype, 'missing_data') unless kase.complaint_subtype.present?
      kase.update_attribute(:priority, 'normal') unless kase.priority.present?
    end
  end
end

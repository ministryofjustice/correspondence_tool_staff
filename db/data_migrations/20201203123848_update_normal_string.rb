class UpdateNormalString < ActiveRecord::DataMigration
  def up
    kases = Case::Base.offender_sar_complaint.all
    kases.each do |kase|
      kase.update_attribute(:priority, 'normal_priority')
    end
  end
end

class AddHasPITExtensionPropertyToCases < ActiveRecord::DataMigration
  def up
    # only try to fix up non-deleted cases
    Case::Base.all.find_each do |kase|
      pit_transitions = kase.transitions
        .where(event: %w[extend_for_pit remove_pit_extension])
        .order(created_at: :desc)

      if pit_transitions.any? && pit_transitions.last.event == "extend_for_pit"
        kase.has_pit_extension = true
        kase.save!
      end
    end
  end
end

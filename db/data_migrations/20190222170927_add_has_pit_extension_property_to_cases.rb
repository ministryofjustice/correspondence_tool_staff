class AddHasPitExtensionPropertyToCases < ActiveRecord::DataMigration
  def up
    Case::Base.unscoped.all.each do |kase|
      pit_transitions = kase.transitions
        .where(event: ['extend_for_pit', 'remove_pit_extension'])
        .order(created_at: :desc)

      if pit_transitions.any? && pit_transitions.last.event == 'extend_for_pit'
        kase.has_pit_extension = true
        kase.save!
      end
    end
  end
end

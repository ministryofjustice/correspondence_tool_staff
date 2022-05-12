class AddStateToCases < ActiveRecord::Migration[5.0]
  def up
    add_column :cases, :current_state, :string
    add_column :cases, :last_transitioned_at, :datetime

    Case::Base.unscoped.all.each do |kase|
      transition = kase.transitions.order(:sort_key).last
      if transition.nil?
        kase.update!(current_state: 'unassigned', last_transitioned_at: kase.created_at)
      else
        transition.record_state_change(kase) unless transition.nil?
      end
      puts "Updated Case Id #{kase.id} with state #{kase.current_state}"
    end
  end

  def down
    remove_column :cases, :current_state
    remove_column :cases, :last_transitioned_at
  end
end

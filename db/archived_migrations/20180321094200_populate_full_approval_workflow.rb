class PopulateFullApprovalWorkflow < ActiveRecord::Migration[5.0]
  class Case::Base < ApplicationRecord
    self.table_name = :cases

    has_many :approver_assignments,
             -> { approving },
             class_name: "Assignment",
             foreign_key: :case_id

    has_many :approving_teams,
             -> { where("state != 'rejected'") },
             class_name: "BusinessUnit",
             through: :approver_assignments,
             source: :team

    def flagged_for_press_office_clearance?
      approving_teams.include?(BusinessUnit.press_office)
    end
  end

  def up
    Case::Base.find_each do |kase|
      if kase.flagged_for_press_office_clearance?
        kase.update!(workflow: "full_approval")
      end
    end
  end

  def down
    execute %(UPDATE cases SET workflow = 'trigger' WHERE workflow = 'full_approval')
  end
end

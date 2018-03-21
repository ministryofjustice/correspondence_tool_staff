class PopulateFullApprovalWorkflow < ActiveRecord::Migration[5.0]
  def up
    Case::Base.find_each do |kase|
      if kase.flagged_for_disclosure_specialist_clearance?
        kase.update(workflow: 'full_approval')
      end
    end
  end

  def down
    execute %/UPDATE cases SET workflow = 'trigger' WHERE workflow = 'full_approval'/
  end
end

class PopulateWorflowOnExistingCases < ActiveRecord::Migration[5.0]
  def up
    Case::Base.find_each do |kase|
      if kase.type_abbreviation == "FOI" && kase.flagged?
        kase.update!(workflow: "trigger")
      else
        kase.update!(workflow: "standard")
      end
    end
  end

  def down
    execute("UPDATE cases set workflow = NULL")
  end
end

class ChangeSarIntoSarStandard < ActiveRecord::DataMigration
  def up
    Case::Base
      .unscope(:where)
      .where("type = ?", "Case::SAR")
      .update_all(type: "Case::SAR::Standard")
  end

  def down
    Case::Base
      .unscope(:where)
      .where("type = ?", "Case::SAR::Standard")
      .update_all(type: "Case::SAR")
  end
end

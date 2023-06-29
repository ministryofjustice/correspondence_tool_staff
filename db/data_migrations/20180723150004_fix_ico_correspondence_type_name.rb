class FixIcoCorrespondenceTypeName < ActiveRecord::DataMigration
  class CorrespondenceType < ApplicationRecord
  end

  def up
    ico = CorrespondenceType.find_by!(abbreviation: "ICO")
    ico.update! name: "Information commissioner office appeal"
  end
end

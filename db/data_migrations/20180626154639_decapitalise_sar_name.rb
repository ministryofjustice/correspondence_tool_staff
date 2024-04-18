class DecapitaliseSARName < ActiveRecord::DataMigration
  def up
    sar = CorrespondenceType.sar
    raise "Unable to find correspondence type SAR" if sar.nil?

    sar.update!(name: "Subject access request")
  end
end

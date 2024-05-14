class AddOffenderSARCorrespondenceType < ActiveRecord::DataMigration
  def up
    Rake::Task["db:seed:dev:teams"].invoke
  end
end

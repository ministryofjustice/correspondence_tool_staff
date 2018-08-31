class PopulateDevTeamsAndUsers < ActiveRecord::DataMigration
  def up
    unless Rails.env.production?
      Rake::Task['db:seed:dev:teams'].invoke
      Rake::Task['db:seed:dev:users'].invoke
    end
  end
end

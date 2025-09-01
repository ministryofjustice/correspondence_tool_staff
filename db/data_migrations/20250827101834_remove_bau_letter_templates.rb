class RemoveBauLetterTemplates < ActiveRecord::DataMigration
  def up
    LetterTemplate.destroy_by(abbreviation: %w[
      bau-prisoner-disclosed-letter
      bau-solicitor-disclosed-letter
    ])
  end
end

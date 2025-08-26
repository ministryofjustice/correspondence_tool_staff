class RemoveBauDisclosedLetters < ActiveRecord::DataMigration
  def up
    rec = LetterTemplate.find_by(abbreviation: "bau-prisoner-disclosed-letter")
    if rec.present?
      rec.destroy!
    end

    rec = LetterTemplate.find_by(abbreviation: "bau-solicitor-disclosed-letter")
    if rec.present?
      rec.destroy!
    end
  end
end

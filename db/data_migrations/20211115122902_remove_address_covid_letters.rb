class RemoveAddressCovidLetters < ActiveRecord::DataMigration
  def up
    rec = LetterTemplate.find_by(abbreviation: "prisoner-acknowledgement-covid")
    if rec.present?
      rec.destroy!
    end

    rec = LetterTemplate.find_by(abbreviation: "solicitor-acknowledgement-covid")
    if rec.present?
      rec.destroy!
    end

    rec = LetterTemplate.find_by(abbreviation: "despatch-confirming-address")
    if rec.present?
      rec.destroy!
    end

    rec = LetterTemplate.find_by(abbreviation: "solicitor-disclosed-covid")
    if rec.present?
      rec.destroy!
    end

    rec = LetterTemplate.find_by(abbreviation: "prisoner-disclosed-covid")
    if rec.present?
      rec.destroy!
    end
  end
end

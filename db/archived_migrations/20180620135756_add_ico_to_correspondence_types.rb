class AddICOToCorrespondenceTypes < ActiveRecord::Migration[5.0]
  class CorrespondenceType < ApplicationRecord
    jsonb_accessor :properties,
                   internal_time_limit: :integer,
                   external_time_limit: :integer,
                   escalation_time_limit: :integer,
                   deadline_calculator_class: :string,
                   default_press_officer: :string,
                   default_private_officer: :string
  end

  # class TeamCorrespondenceTypeRole < ActiveRecord::Base
  # end

  def up
    ico = CorrespondenceType.create!(name: "Information Commissioner Office appeal.",
                                     abbreviation: "ICO",
                                     escalation_time_limit: nil,
                                     internal_time_limit: 10,
                                     external_time_limit: nil,
                                     deadline_calculator_class: nil)
    BusinessUnit.all.each do |bu|
      bu.correspondence_type_ids += [ico.id]
    end
  end

  def down
    ico = CorrespondenceType.find_by(abbreviation: "ICO")

    join_recs = TeamCorrespondenceTypeRole.where(correspondence_type_id: [ico.id])
    join_recs.map(&:destroy)

    ico.destroy!
  end
end

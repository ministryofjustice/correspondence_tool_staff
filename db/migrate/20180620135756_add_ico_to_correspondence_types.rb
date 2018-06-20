class AddIcoToCorrespondenceTypes < ActiveRecord::Migration[5.0]
  def up
    require File.join(Rails.root, 'db', 'seeders', 'correspondence_type_seeder')
    CorrespondenceTypeSeeder.new.seed!

    ico_ids = [
      CorrespondenceType.ico_foi.id,
      CorrespondenceType.ico_sar.id
    ]

    BusinessUnit.all.each do | bu|
      existing_correspondence_type_ids = bu.correspondence_type_ids
      bu.correspondence_type_ids = existing_correspondence_type_ids + ico_ids

    end
  end


  def down
    cts = CorrespondenceType.where(abbreviation: %w{ ICO_SAR ICO_FOI } )
    if cts.any?
      join_recs = TeamCorrespondenceTypeRole.where(correspondence_type_id: cts.map(&:id))
      join_recs.map(&:destroy)
    end
    cts.map(&:destroy)
  end
end

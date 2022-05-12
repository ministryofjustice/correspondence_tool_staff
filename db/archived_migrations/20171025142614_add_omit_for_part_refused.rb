class AddOmitForPartRefused < ActiveRecord::Migration[5.0]
  def up
    add_column :case_closure_metadata, :omit_for_part_refused, :boolean, default: false

    CaseClosure::Metadatum.reset_column_information
    CaseClosure::Exemption.all.each do |ex|
      ex.update!(omit_for_part_refused: true) if ex.abbreviation == 'cost'
    end
  end

  def down
    remove_column :case_closure_metadata, :omit_for_part_refused
  end
end

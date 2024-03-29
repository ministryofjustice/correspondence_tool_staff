class AddRequiresRefusalReasonToCaseClosureMetadata < ActiveRecord::Migration[5.0]
  # rubocop:disable Rails/ReversibleMigration
  def change
    add_column :case_closure_metadata, :requires_refusal_reason, :boolean, default: false

    execute "UPDATE case_closure_metadata SET requires_refusal_reason = true WHERE abbreviation IN ('part', 'refused')"
  end
  # rubocop:enable Rails/ReversibleMigration
end

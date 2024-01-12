class AddThirdPartyEmailToOffender < ActiveRecord::Migration[6.1]
  def change
    add_column :offenders, :third_party_email, :jsonb
  end
end

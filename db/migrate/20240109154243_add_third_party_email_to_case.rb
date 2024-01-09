class AddThirdPartyEmailToCase < ActiveRecord::Migration[6.1]
  def change
    add_column :cases, :third_party_email, :text
  end
end

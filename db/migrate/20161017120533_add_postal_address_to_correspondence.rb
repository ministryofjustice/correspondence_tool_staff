class AddPostalAddressToCorrespondence < ActiveRecord::Migration[5.0]
  def change
    add_column :correspondence, :postal_address, :string
  end
end

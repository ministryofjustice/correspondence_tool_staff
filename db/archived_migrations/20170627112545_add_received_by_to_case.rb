class AddReceivedByToCase < ActiveRecord::Migration[5.0]
  class Case < ActiveRecord::Base
    self.inheritance_column = :_type_not_used
  end

  def up
    Case.connection.transaction do
      create_enum :cases_delivery_methods,
                  'sent_by_email',
                  'sent_by_post'
      add_column :cases, :delivery_method, :cases_delivery_methods

      Case.all.each do |kase|
        kase.update delivery_method: :sent_by_email
      end
    end
  end

  def down
    remove_column :cases, :delivery_method

    drop_enum :cases_delivery_methods
  end
end

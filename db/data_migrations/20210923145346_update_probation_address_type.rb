class UpdateProbationAddressType < ActiveRecord::DataMigration
  def up
    cr = CategoryReference.find_by(category: 'contact_type', code: 'probation')

    cr.value = 'Probation'

    cr.save
  end

  def down
    cr = CategoryReference.find_by(category: 'contact_type', code: 'probation')

    cr.value = 'Probation centre'

    cr.save
  end
end

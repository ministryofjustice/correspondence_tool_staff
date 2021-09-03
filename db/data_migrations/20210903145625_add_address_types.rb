class AddAddressTypes < ActiveRecord::DataMigration
  def up
    category_references = [
      { 
        category: 'address_type',
        code: 'prison',
        value: 'Prison',
        display_order: 10
      },
      { 
        category: 'address_type',
        code: 'probation',
        value: 'Probation centre',
        display_order: 20
      },
      { 
        category: 'address_type',
        code: 'solicitor',
        value: 'Solicitor',
        display_order: 30
      },
      { 
        category: 'address_type',
        code: 'branston',
        value: 'Branson',
        display_order: 40
      },
      { 
        category: 'address_type',
        code: 'hmpps_hq',
        value: 'HMPPS HQ',
        display_order: 50
      },
      { 
        category: 'address_type',
        code: 'hmcts',
        value: 'HMCTS',
        display_order: 60
      },
      { 
        category: 'address_type',
        code: 'other',
        value: 'Other',
        display_order: 70
      }
    ]

    category_references.each do |category_reference|
      CategoryReference.create(category_reference)
    end
  end

  def down
    CategoryReference.where(category: 'address_type').delete_all
  end
end

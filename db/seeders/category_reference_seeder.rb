module CategoryReferenceSeeder
  class ContactTypeSeeder
    @@category_references = [
      {
        category: 'contact_type',
        code: 'prison',
        value: 'Prison',
        display_order: 10
      },
      {
        category: 'contact_type',
        code: 'probation',
        value: 'Probation',
        display_order: 20
      },
      {
        category: 'contact_type',
        code: 'solicitor',
        value: 'Solicitor',
        display_order: 30
      },
      {
        category: 'contact_type',
        code: 'branston',
        value: 'Branston',
        display_order: 40
      },
      {
        category: 'contact_type',
        code: 'hmpps_hq',
        value: 'HMPPS HQ',
        display_order: 50
      },
      {
        category: 'contact_type',
        code: 'hmcts',
        value: 'HMCTS',
        display_order: 60
      },
      {
        category: 'contact_type',
        code: 'other',
        value: 'Other',
        display_order: 70
      }
    ]

    def self.seed!
      @@category_references.each do |category_reference|
        CategoryReference.find_or_create_by!(category_reference)
      end
    end

    def self.unseed!
      CategoryReference.where(category: :contact_type).delete_all
    end
  end
end

module CaseCategoryReferenceSeeder
  class ReasonsForLateness

    def self.seed!
      seed_reasons_for_lateness
    end

    def self.unseed!
      CategoryReference.delete_all
    end

    def self.seed_reasons_for_lateness
      rec = CategoryReference.find_by(code: 'other', category: 'reasons_for_lateness')
      rec = CategoryReference.new if rec.nil?

      rec.update!(category: 'reasons_for_lateness',
                  code: 'large_case_to_vet',
                  value: 'Large case to vet (case over 5000 pages)',
                  display_order: 10)

      rec = CategoryReference.find_by(code: 'date_received_delay', category: 'reasons_for_lateness')
      rec = CategoryReference.new if rec.nil?
      rec.update!(category: 'reasons_for_lateness',
                  code: 'large_case_to_vet',
                  value: 'Data received after day 20',
                  display_order: 20)

      rec = CategoryReference.find_by(code: 'other', category: 'reasons_for_lateness')
      rec = CategoryReference.new if rec.nil?
      rec.update!(category: 'reasons_for_lateness',
                  code: 'other',
                  value: 'Other',
                  display_order: 30)
    end

  end
end

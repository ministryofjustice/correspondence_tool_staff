module Stats
  module Warehouse
    # Separated the Sync operation from the ActiveRecord Warehouse::CaseReport
    # to prevent the full AR base class from being loaded
    class CasesReportSync
      # +MAPPINGS+ could be refactored so that the respective class types
      # contain the required information/execution output. The current
      # implementation is experimental, less intrusive and is easier to reason
      # about in this central place. The `fields` key links the Cases Report
      # field to the source of the information.
      #
      # Each class Mapping is defined as:
      #
      # {
      #   ClassNameString: {
      #     fields: %w[
      #       0 or more field names present in warehouse_cases_report
      #       or in another table, used to pass to `execute`
      #     ],
      #     parameter: :key_name_used_by_where_clause,
      #     execute: ->(record, query){
      #       method that outputs an Array of `Case::Base` using the `query`
      #       string
      #     }
      #   },
      # }
      #
      # This is an alternative implementation to using if/else statements
      # with hard coded `where` statements
      MAPPINGS = {
        'Case::Base': {
          fields: [],
          parameter: nil,
          execute: ->(record, _){ [record] }
        },
        'CaseClosure::Metadatum': {
          fields: %w[
              info_held_status_id
              refusal_reason_id
              outcome_id
              appeal_outcome_id
            ],
          parameter: :metadata_id,
          execute: ->(record, query){ self.find_cases(record, query, :metadata_id) },
        },
        'CaseTransition': {
          fields: [],
          parameter: nil,
          execute: ->(record, _){ [record.case] },
        },
        'Team': {
          fields: %w[
              responding_team_id
              business_group_id
              directorate_id
            ],
          parameter: :team_id,
          execute: ->(record, query){ self.find_cases(record, query, :team_id) },
        },
        'TeamProperty': {
          fields: %w[
              director_general_name_property_id
              director_name_property_id
              deputy_director_name_property_id
            ],
          parameter: :property_id,
          execute: ->(record, query){ self.find_cases(record, query, :property_id) },
        },
        'User': {
          fields: %w[
              creator_id
              casework_officer_user_id
              responder_id
            ],
          parameter: :user_id,
          execute: ->(record, query){ self.find_cases(record, query, :user_id) },
        },
      }.freeze

      # Ensure the warehouse remains in sync with changes elsewhere
      # in the database.
      #
      # @note (mseedat-moj): Checking Class Type could be considered a
      # code-smell, took the pragmatic/simpler decision to maintain sync
      # operations in one place for this initial 'alpha' implementation
      def initialize(record)
        syncable, mapping_klass = self.class.syncable?(record)
        return unless syncable

        self.class.execute_setting(record, MAPPINGS[mapping_klass.to_s.to_sym])
      end

      def self.execute_setting(record, setting)
        query = setting[:fields]
          .map { |f| "#{f} = :#{setting[:parameter]}" }
          .join(' OR ')

        setting[:execute]
          .call(record, query)
          .each { |kase| ::Warehouse::CaseReport.generate(kase) }
      end

      def self.find_cases(record, query, parameter)
        ::Warehouse::CaseReport
          .includes(:case)
          .where("#{query}", parameter.to_sym => record.id)
          .map(&:case)
      end

      def self.syncable?(record)
        mapping_klass = nil

        result = MAPPINGS.keys.any? do |type|
          mapping_klass = type
          record.kind_of?(type.to_s.constantize)
        end

        [result, mapping_klass]
      end
    end
  end
end

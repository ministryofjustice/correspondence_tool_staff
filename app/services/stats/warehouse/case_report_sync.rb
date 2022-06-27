module Stats
  module Warehouse
    # Separated the Sync operation from the ActiveRecord Warehouse::CaseReport
    # to prevent the full AR base class from being loaded
    class CaseReportSync
      # +MAPPINGS+ could be refactored so that the respective class types
      # contain the required information/execution output. The current
      # implementation is experimental, less intrusive and is easier to reason
      # about in this central place. The `fields` key links the Cases Report
      # field to the source of the information (unless an ActiveRecord
      # association is already defined).
      #
      # Each class Mapping is defined as:
      #
      # {
      #   ClassNameString: {
      #     fields: %w[
      #       0 or more field names present in warehouse_cases_report
      #       or in another table, used to pass to `execute`
      #     ],
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
        'Assignment': {
          fields: [],
          execute: ->(record, _) { [record.case] },
        },
        'Case::Base': {
          fields: [],
          execute: ->(record, _) { [record] }
        },
        'CaseClosure::Metadatum': {
          fields: %w[
              info_held_status_id
              refusal_reason_id
              outcome_id
              appeal_outcome_id
            ],
          execute: ->(record, query) { self.find_cases(record, query) },
        },
        'CaseTransition': {
          fields: [],
          execute: ->(record, _) { [record.case] },
        },
        'Team': {
          fields: %w[
              responding_team_id
              business_group_id
              directorate_id
            ],
          execute: ->(record, query) { self.find_cases(record, query) },
        },
        'TeamProperty': {
          fields: %w[
              director_general_name_property_id
              director_name_property_id
              deputy_director_name_property_id
            ],
          execute: ->(record, query) { self.find_cases(record, query) },
        },
        'User': {
          fields: %w[
              creator_id
              casework_officer_user_id
              responder_id
            ],
          execute: ->(record, query) { self.find_cases(record, query) },
        },
      }.freeze

      # Ensure the warehouse remains in sync with changes elsewhere
      # in the database.
      #
      # @note (mseedat-moj): Checking Class Type could be considered a
      # code-smell, took the pragmatic/simpler decision to maintain sync
      # operations in one place for this initial 'alpha' implementation
      def initialize(record)
        raise ArgumentError.new('record must be an ApplicationRecord') unless record.is_a? ApplicationRecord

        syncable, mapping_klass = self.class.syncable?(record)

        if syncable
          cases = self.class.affected_cases(
            record,
            MAPPINGS[mapping_klass.to_s.to_sym]
          )
          self.class.sync(cases)
        end
      end

      def self.affected_cases(record, setting)
        # Where clause conditions to search against CaseReport
        query = setting[:fields]
          .map { |f| "#{f} = :param" }
          .join(' OR ')

        # Get all Case(s) related to the CaseReport(s)
        setting[:execute].call(record, query)
      end

      def self.sync(cases)
        Array.wrap(cases).compact.map do |kase|
          ::Warehouse::CaseReport.generate(kase)
        end
      end

      def self.find_cases(record, query)
        ::Warehouse::CaseReport
          .includes(:case)
          .where([query, param: record.id])
          .map(&:case)
      end

      def self.syncable?(record)
        mapping_klass = nil

        result = MAPPINGS.keys.any? do |type|
          if record.is_a?(type.to_s.constantize)
            !!(mapping_klass = type)
          end
        end

        [result, mapping_klass]
      end
    end
  end
end

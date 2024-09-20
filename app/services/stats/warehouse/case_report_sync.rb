module Stats
  module Warehouse
    # The goal of this class is to find a single case that can be synced.
    # If there are multiple affected cases then new jobs are created
    # for each case to be synced.
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
      #       method that either returns a case object or creates sync
      #       jobs for each affected case found
      #     }
      #   },
      # }
      MAPPINGS = {
        'Assignment': {
          fields: [],
          execute: ->(record, _) { record.case },
        },
        'Case::Base': {
          fields: [],
          execute: ->(record, _) { record },
        },
        'CaseClosure::Metadatum': {
          fields: %w[
            info_held_status_id
            refusal_reason_id
            outcome_id
            appeal_outcome_id
          ],
          execute: ->(record, query) { find_cases(record, query) },
        },
        'CaseTransition': {
          fields: [],
          execute: ->(record, _) { record.case },
        },
        'Team': {
          fields: %w[
            responding_team_id
            business_group_id
            directorate_id
          ],
          execute: ->(record, query) { find_cases(record, query) },
        },
        'TeamProperty': {
          fields: %w[
            director_general_name_property_id
            director_name_property_id
            deputy_director_name_property_id
          ],
          execute: ->(record, query) { find_cases(record, query) },
        },
        'User': {
          fields: %w[
            creator_id
            casework_officer_user_id
            responder_id
          ],
          execute: ->(record, query) { find_cases(record, query) },
        },
      }.freeze

      # Ensure the warehouse remains in sync with changes elsewhere in the database.
      def initialize(record)
        raise ArgumentError, "record must be an ApplicationRecord" unless record.is_a? ApplicationRecord

        syncable, mapping_klass = self.class.syncable?(record)

        if syncable
          kase = self.class.affected_cases(
            record,
            MAPPINGS[mapping_klass.to_s.to_sym],
          )

          self.class.sync(kase)
        end
      end

      def self.affected_cases(record, setting)
        query = setting[:fields]
          .map { |f| "#{f} = :param" }
          .join(" OR ")

        setting[:execute].call(record, query)
      end

      def self.sync(kase)
        return unless kase.is_a? Case::Base

        ::Warehouse::CaseReport.generate(kase)
      end

      def self.find_cases(record, query)
        case_ids = ::Warehouse::CaseReport
          .where([query, { param: record.id }])
          .map(&:case_id)

        case_ids.each do |id|
          ::Warehouse::CaseSyncJob.perform_later("Case::Base", id)
        end

        nil
      end

      def self.syncable?(record)
        mapping_klass = nil

        result = MAPPINGS.keys.any? do |type|
          if record.is_a?(type.to_s.constantize)
            !(mapping_klass = type).nil?
          end
        end

        [result, mapping_klass]
      end
    end
  end
end

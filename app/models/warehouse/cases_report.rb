module Warehouse
  class CasesReport < ApplicationRecord

    self.table_name = 'warehouse_cases_report'

    belongs_to :case, class_name: 'Case::Base'

    CASE_BATCH_SIZE = 500

    # +MAPPINGS+ could be refactored so that the respective class types
    # contain the required information/execution output. However, the
    # current implementation is experimental and less intrusive. The `fields`
    # key links the Cases Report field to the source of the information.
    # Each class Mapping is defined as:
    #
    # {
    #   ClassNameString: {
    #     fields: %w[
    #       0 or more field names present in warehouse_cases_report
    #       or in another table, used to pass to `execute`
    #     ],
    #     parameter: :key_name_used_by_where_clause,
    #     execute: ->(_){ method that outputs an Array of `Case::Base` }
    #   },
    # }
    #
    # This is an alternative implementation to using if/else statements
    # with hard coded `where` statements
    MAPPINGS = {
      'Case::Base': {
        fields: [],
        parameter: nil,
        execute: ->(_){ [self] }
      },
      'CaseClosure': {
        fields: %w[
            info_held_status_id
            refusal_reason_id
            outcome_id
            appeal_outcome_id
          ],
        parameter: :metadata_id,
        execute: ->(sql){ Case::Base.where("#{sql}", metadata_id: self.id) },
      },
      'CaseTransition': {
        fields: [],
        parameter: nil,
        execute: ->(_){ [self.case] },
      },
      'Team': {
        fields: %w[
            responding_team_id
            business_group_id
            directorate_id
          ],
        parameter: :team_id,
        execute: ->(sql){ CasesReport.includes(:case).where("#{sql}", team_id: self.id).map(&:case) },
      },
      'TeamProperty': {
        fields: %w[
            director_general_name_property_id
            director_name_property_id
            deputy_director_name_property_id
          ],
        parameter: :property_id,
        execute: ->(sql){ CasesReport.includes(:case).where("#{sql}", property_id: self.id).map(&:case) },
      },
      'User': {
        fields: %w[
            creator_id
            casework_officer_user_id
            responder_id
          ],
        parameter: :user_id,
        execute: ->(sql){ CasesReport.includes(:case).where("#{sql}", user_id: self.id).map(&:case) },
      },
    }.freeze


    #rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    def self.generate(kase)
      if !(case_report = CasesReport.find_by(case_id: kase.id))
        case_report = self.new
        case_report.case_id = kase.id
      end

      # Relationship fields - for data-integrity checks
      case_report.creator_id = kase.creator.id
      case_report.responding_team_id = kase.responding_team&.id
      case_report.responder_id = kase.responder&.id
      case_report.casework_officer_user_id = kase.decorate.casework_officer_user&.id
      case_report.business_group_id = kase.responding_team&.business_group&.id
      case_report.directorate_id = kase.responding_team&.directorate&.id
      case_report.director_general_name_property_id = kase.responding_team&.business_group&.properties&.lead&.singular_or_nil&.id # Director General name
      case_report.director_name_property_id = kase.responding_team&.directorate&.properties&.lead&.singular_or_nil&.id # Director name
      case_report.deputy_director_name_property_id = kase.responding_team&.properties&.lead&.singular_or_nil&.id # Deputy Director name

      # Report fields - for output
      case_report.number = kase.number
      case_report.case_type = kase.decorate.pretty_type
      case_report.current_state = I18n.t("helpers.label.state_selector.#{kase.current_state}")
      case_report.responding_team = kase.responding_team&.name
      case_report.responder = kase.responder&.full_name
      case_report.date_received = kase.received_date
      case_report.internal_deadline = kase.flagged? ? kase.internal_deadline : nil
      case_report.external_deadline = kase.external_deadline
      case_report.date_responded = kase.date_responded
      case_report.date_compliant_draft_uploaded = kase.date_draft_compliant
      case_report.trigger = kase.flagged? ? 'Yes' : nil
      case_report.name = kase.name
      case_report.requester_type = kase.sar? ? nil : kase.requester_type.humanize
      case_report.message = self.dequote_and_truncate(kase.message)
      case_report.info_held = kase.info_held_status&.name
      case_report.outcome = kase.outcome&.name
      case_report.refusal_reason = kase.refusal_reason&.name
      case_report.exemptions = kase.exemptions.map{ |x| CaseClosure::Exemption.section_number_from_id(x.abbreviation) }.join(',')
      case_report.postal_address = kase.postal_address
      case_report.email = kase.email
      case_report.appeal_outcome = kase.appeal_outcome&.name
      case_report.third_party = kase.respond_to?(:third_party) ? self.humanize_boolean(kase.third_party) : nil
      case_report.reply_method = kase.respond_to?(:reply_method) ? kase.reply_method.humanize : nil
      case_report.sar_subject_type = kase.respond_to?(:subject_type) ? kase.subject_type.humanize : nil
      case_report.sar_subject_full_name = kase.respond_to?(:subject_full_name) ? kase.subject_full_name : nil
      case_report.business_unit_responsible_for_late_response = kase.decorate.late_team_name
      case_report.extended = extension_count(kase) > 0 ? 'Yes' : 'No'
      case_report.extension_count = self.extension_count(kase)
      case_report.deletion_reason = kase.reason_for_deletion
      case_report.casework_officer = kase.casework_officer
      case_report.created_by = kase.creator.full_name
      case_report.date_created = kase.created_at # Date created

      # Some of this info can be seen in the Case > Teams page
      # Business group: of the responding Business Unit/KILO (e.g. Comms & Info)
      # Director general: head of the business group
      # Director name: head of directorate
      # Deputy Director: head of business unit
      case_report.business_group = kase.responding_team&.business_group&.name
      case_report.directorate_name = kase.responding_team&.directorate&.name
      case_report.director_general_name = kase.responding_team&.business_group&.team_lead # Director General name
      case_report.director_name = kase.responding_team&.directorate&.team_lead # Director name
      case_report.deputy_director_name = kase.responding_team&.team_lead # Deputy Director name

      # Draft Timeliness related information
      case_report.draft_in_time = self.humanize_boolean(kase.within_draft_deadline?) # Draft in time
      case_report.in_target = self.humanize_boolean(kase.response_in_target?) # In Target
      case_report.number_of_days_late = kase.num_days_late # Number of days late

      case_report.save!
    end
    #rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

    def self.generate_all
      self.process_cases(Case::Base.all)
    end

    def self.reconcile
      [
        self.reconcile_missing_cases,
        self.reconcile_deleted_cases
      ]
    end

    def self.reconcile_missing_cases
      query =
        Case::Base
          .joins('LEFT OUTER JOIN warehouse_cases_report ON warehouse_cases_report.case_id = cases.id')
          .where("cases.deleted = 'false' AND warehouse_cases_report.case_id IS NULL")

      self.process_cases(query)
    end

    # Because of foreign-key constraints should not be able to have any orphan
    # CasesReport entries but included here for completeness
    def self.reconcile_deleted_cases
      self
        .joins('LEFT OUTER JOIN cases ON cases.id = warehouse_cases_report.case_id')
        .where("cases.deleted = 'true' OR cases.id is NULL")
        .delete_all
    end

    # Ensure the warehouse remains in sync with changes elsewhere
    # in the database.
    #
    # Although checking Class type is considered a code-smell, took the
    # pragmatic/simpler decision to maintain sync operations in one place.
    def self.sync(record)
      mapping_klass = nil

      return unless MAPPINGS.keys.any? do |type|
        mapping_klass = type
        record.kind_of?(type.to_s.constantize)
      end

      settings = MAPPINGS[mapping_klass.to_s.to_sym]
      query = settings[:fields]
        .map { |f| "#{f} = :#{settings[:parameter]}" }
        .join(' OR ')

      settings[:execute].call(query).each { |kase| self.generate(kase) }
    end

    def self.process_cases(query)
      count = 0

      query.in_batches(of: CASE_BATCH_SIZE) do |batch|
        batch.each do |kase|
          self.generate(kase)
          count += 1
        end

        GC.start  # Clear up allocated objects
        sleep(10) # Throttle
      end

      count
    end

    # Copied from CSVExporter
    def self.extension_count(kase)
      pit_count, sar_count = 0, 0
      kase.transitions.map(&:event).each do |event|
        case event
        when CaseTransition::EXTEND_FOR_PIT_EVENT
          pit_count += 1
        when CaseTransition::REMOVE_PIT_EXTENSION_EVENT
          pit_count = 0
        when CaseTransition::EXTEND_SAR_DEADLINE_EVENT
          sar_count += 1
        when CaseTransition::REMOVE_SAR_EXTENSION_EVENT
          sar_count = 0
        end
      end
      pit_count + sar_count
    end

    # Copied from CSVExporter
    def self.dequote_and_truncate(text)
      text.tr('"', '').tr("'", '')[0..4000]
    end

    # Copied from CSVExporter
    def self.humanize_boolean(boolean)
      boolean ? 'Yes' : nil
    end
  end
end

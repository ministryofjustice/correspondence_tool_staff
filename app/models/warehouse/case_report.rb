module Warehouse
  class CaseReport < ApplicationRecord
    self.table_name = 'warehouse_case_reports'

    belongs_to :case, class_name: 'Case::Base'

    CASE_BATCH_SIZE = 500

    CLASS_CASE_REPORT_DATA_PROCESSES = {
      "Case::SAR::Offender" => ['process_offender_sar'], 
      "Case::SAR::OffenderComplaint" => %w[process_offender_sar process_offender_sar_complaint], 
      "Case::ICO::FOI" => ['process_ico'],
      "Case::ICO::SAR" => ['process_ico']    
    }.freeze

    # Class methods to allow this class to be used in async jobs
    class << self
      def for(kase)
        kase.warehouse_case_report || self.new(case_id: kase.id)
      end

      # Every field is deliberately set explicitly, please do not use any
      # clever meta-magic as each field has a history of how it should
      # be calculated and therefore needs to be readily understood
      #
      #rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
      def generate(kase)
        case_report = self.for(kase)

        # Relationship fields - for data-integrity checks
        case_report.creator_id = kase.creator.id
        case_report.responding_team_id = kase.responding_team&.id
        case_report.responder_id = kase.responder&.id
        case_report.casework_officer_user_id = kase.casework_officer_user&.id
        case_report.business_group_id = kase.responding_team&.business_group&.id
        case_report.directorate_id = kase.responding_team&.directorate&.id
        case_report.director_general_name_property_id = kase.responding_team&.business_group&.properties&.lead&.singular_or_nil&.id # Director General name
        case_report.director_name_property_id = kase.responding_team&.directorate&.properties&.lead&.singular_or_nil&.id # Director name
        case_report.deputy_director_name_property_id = kase.responding_team&.properties&.lead&.singular_or_nil&.id # Deputy Director name
        case_report.info_held_status_id = kase.info_held_status&.id
        case_report.refusal_reason_id = kase.refusal_reason&.id
        case_report.outcome_id = kase.outcome&.id
        case_report.appeal_outcome_id = kase.appeal_outcome&.id
        
        # Report fields - for output
        case_report.number = kase.number
        case_report.case_type = kase.decorate.pretty_type
        case_report.current_state = kase.decorate.status
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
        case_report.exemptions = self.exemptions(kase)

        case_report.postal_address = kase.postal_address
        case_report.email = kase.email
        case_report.appeal_outcome = kase.appeal_outcome&.name
        case_report.third_party = kase.respond_to?(:third_party) ? self.humanize_boolean(kase.third_party) : nil
        case_report.reply_method = kase.respond_to?(:reply_method) ? kase.reply_method.humanize : nil
        case_report.sar_subject_type = kase.respond_to?(:subject_type) ? kase.subject_type.humanize : nil
        case_report.sar_subject_full_name = kase.respond_to?(:subject_full_name) ? kase.subject_full_name : nil
        case_report.business_unit_responsible_for_late_response = kase.decorate.late_team_name
        case_report.extended = self.extension_count(kase) > 0 ? 'Yes' : 'No'
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
        case_report.number_of_days_taken = kase.num_days_taken
        case_report.number_of_days_taken_after_extension = kase.num_days_taken_after_extension
        case_report.original_internal_deadline = kase.respond_to?(:original_internal_deadline) ? kase.original_internal_deadline : nil
        case_report.original_external_deadline = kase.respond_to?(:original_external_deadline) ? kase.original_external_deadline : nil
        case_report.num_days_late_against_original_deadline = kase.respond_to?(:original_external_deadline) ? kase.num_days_late_against_original_deadline : nil

        process_class_related_process(kase,case_report)
        case_report.save!
        case_report
      end
      #rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

      def generate_all
        self.process_cases(Case::Base.all)
      end

      def reconcile(job_size=nil)
        [
          self.reconcile_missing_cases(job_size),
          self.reconcile_deleted_cases
        ]
      end

      def reconcile_missing_cases(job_size=nil)
        query =
        Case::Base
          .joins('LEFT OUTER JOIN warehouse_case_reports ON warehouse_case_reports.case_id = cases.id')
          .where("cases.deleted = 'false' AND warehouse_case_reports.case_id IS NULL")

        query = query.limit(job_size) if job_size
        self.process_cases(query)
      end

      # Because of foreign-key constraints, should not be able to have any orphan
      # CaseReport entries but included here for completeness
      def reconcile_deleted_cases
        self
          .joins('LEFT OUTER JOIN cases ON cases.id = warehouse_case_reports.case_id')
          .where("cases.deleted = 'true' OR cases.id is NULL")
          .delete_all
      end

      def process_cases(query, batch_size: CASE_BATCH_SIZE, throttle: true)
        count = 0

        query.in_batches(of: batch_size) do |batch|
          batch.each do |kase|
            self.generate(kase)
            count += 1
          end

          GC.start  # Clear up allocated objects
          sleep(10) if throttle
        end

        count
      end


      # Methods copied from CSVExporter

      def extension_count(kase)
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

      def dequote_and_truncate(text)
        text.tr('"', '').tr("'", '')[0..4000]
      end

      def humanize_boolean(boolean)
        boolean ? 'Yes' : nil
      end

      def process_class_related_process(kase, case_report)
        (CLASS_CASE_REPORT_DATA_PROCESSES[kase.class.name] || []).each do | process_function_name |
          self.send(process_function_name, kase, case_report)
        end
      end

      def process_offender_sar(kase, case_report)
        case_report.third_party_company_name = kase.third_party_company_name
        case_report.number_of_exempt_pages = kase.number_exempt_pages
        case_report.number_of_final_pages = kase.number_final_pages
        case_report.number_of_days_for_vetting = kase.number_of_days_for_vetting
        case_report.user_dealing_with_vetting = kase.user_dealing_with_vetting&.full_name
        case_report.user_id_dealing_with_vetting = kase.user_dealing_with_vetting&.id
      end 

      def process_offender_sar_complaint(kase, case_report)
        case_report.complaint_subtype = kase.complaint_subtype.humanize
        case_report.priority = kase.priority.humanize
        case_report.total_cost = kase.total_cost
        case_report.settlement_cost = kase.settlement_cost
      end 

      def process_ico(kase, case_report)
        case_report.info_held_status_id = kase.original_case.info_held_status&.id
        case_report.refusal_reason_id = kase.original_case.refusal_reason&.id
        case_report.outcome_id = kase.original_case.outcome&.id

        case_report.info_held = kase.original_case.info_held_status&.name 
        case_report.outcome = kase.original_case.outcome&.name
        case_report.refusal_reason = kase.original_case.refusal_reason&.name
        case_report.exemptions = self.exemptions(kase.original_case)
        case_report.appeal_outcome = kase.decorate.pretty_ico_decision
      end

      def exemptions(kase)
        kase.exemptions.map{ |x| CaseClosure::Exemption.section_number_from_id(x.abbreviation) }.join(',')
      end

    end
  end
end

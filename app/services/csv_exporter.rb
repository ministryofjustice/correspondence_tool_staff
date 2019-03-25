require 'csv'

class CSVExporterError < RuntimeError; end

class CSVExporter
  CSV_COLUMN_HEADINGS = [
    'Number',
    'Case type',
    'Current state',
    'Responding team',
    'Responder',
    'Date received',
    'Internal deadline',
    'External deadline',
    'Date responded',
    'Date compliant draft uploaded',
    'Trigger',
    'Name',
    'Requester type',
    'Message',
    'Info held',
    'Outcome',
    'Refusal reason',
    'Exemptions',
    'Postal address',
    'Email',
    'Appeal outcome',
    'Third party',
    'Reply method',
    'SAR Subject type',
    'SAR Subject full name',
    'Business unit responsible for late response',
    'Extended',
    'Extension Count',
    'Casework officer',
    'Created by',
    'Date created',
    'Business group',
    'Directorate name',
    'Director General name',
    'Director name',
    'Deputy Director name',
    'Draft in time',
    'In target',
    'Number of days late',
  ]

  def initialize(kase)
    @kase = kase
  end

  def to_csv #rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity
    begin
      [
        @kase.number,
        @kase.decorate.pretty_type,
        I18n.t("helpers.label.state_selector.#{@kase.current_state}"),
        @kase.responding_team&.name,
        @kase.responder&.full_name,
        @kase.received_date&.to_s,
        @kase.flagged? ? @kase.internal_deadline&.to_s : nil,
        @kase.external_deadline&.to_s,
        @kase.date_responded&.to_s,
        @kase.date_draft_compliant&.to_s,
        @kase.flagged? ? 'Yes' : nil,
        @kase.name,
        @kase.sar? ? nil : @kase.requester_type.humanize,
        dequote_and_truncate(@kase.message),
        @kase.info_held_status&.name,
        @kase.outcome&.name,
        @kase.refusal_reason&.name,
        @kase.exemptions.map{ |x| CaseClosure::Exemption.section_number_from_id(x.abbreviation) }.join(','),
        @kase.postal_address,
        @kase.email,
        @kase.appeal_outcome&.name,
        @kase.respond_to?(:third_party) ? humanize_boolean(@kase.third_party) : nil,
        @kase.respond_to?(:reply_method) ? @kase.reply_method.humanize : nil,
        @kase.respond_to?(:subject_type) ? @kase.subject_type.humanize : nil,
        @kase.respond_to?(:subject_full_name) ? @kase.subject_full_name : nil,
        @kase.decorate.late_team_name,
        extension_count(@kase) > 0 ? 'Yes' : 'No',
        extension_count(@kase),
        casework_officer(@kase),
        @kase.creator.full_name,
        @kase.created_at.strftime('%F'), # Date created

        # Some of this info can be seen in the Case > Teams page
        # Business group: of the responding Business Unit/KILO (e.g. Comms & Info)
        # Director general: head of the business group
        # Director name: head of directorate
        # Deputy Director: head of business unit
        @kase.responding_team&.business_group&.name,
        @kase.responding_team&.directorate&.name,
        @kase.responding_team&.business_group&.team_lead, # Director General name
        @kase.responding_team&.directorate&.team_lead, # Director name
        @kase.responding_team&.team_lead, # Deputy Director name

        draft_in_time(@kase), # Draft in time
        in_target(@kase),
        num_days_late(@kase),
      ]
    rescue => err
      raise CSVExporterError.new("Error encountered formatting case id #{@kase.id} as CSV:\nOriginal error: #{err.class} #{err.message}")
    end
  end

  private

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

  def num_days_late(kase)
    if kase.date_draft_compliant.present? && kase.internal_deadline.present?
      days = (kase.date_draft_compliant - kase.internal_deadline).to_i
      days > 0 ? days : nil
    end
  end

  # Caseworker officer is blank for non-trigger and
  # always a disclosure specialist for trigger cases.
  # Note Case#assigned_disclosure_specialist throws an exception if no
  # 'approving' assignees are found
  def casework_officer(kase)
    return unless kase.workflow == 'trigger'

    kase.assigned_disclosure_specialist.user.full_name
  end

  def draft_in_time(kase)
    return unless kase.respond_to?(:date_draft_compliant)

    humanize_boolean(kase.within_draft_deadline?)
  end

  # Note Case#business_unit_responded_in_time? throws an exception if
  # no 'respond' events are found
  def in_target(kase)
    humanize_boolean(kase.business_unit_responded_in_time?)
  end
end

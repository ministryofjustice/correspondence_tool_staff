require "csv"

class CSVExporterError < RuntimeError; end

class CSVExporter
  CSV_COLUMN_HEADINGS = [
    "Number",
    "Case type",
    "Current state",
    "Responding team",
    "Responder",
    "Date received",
    "Internal deadline",
    "External deadline",
    "Date responded",
    "Date compliant draft uploaded",
    "Trigger",
    "Name",
    "Requester type",
    "Message",
    "Info held",
    "Outcome",
    "Refusal reason",
    "Exemptions",
    "Postal address",
    "Email",
    "Appeal outcome",
    "Third party",
    "Reply method",
    "SAR Subject type",
    "SAR Subject full name",
    "Business unit responsible for late response",
    "Extended",
    "Extension Count",
    "Deletion Reason",
    "Casework officer",
    "Created by",
    "Date created",
    "Business group",
    "Directorate name",
    "Director General name",
    "Director name",
    "Deputy Director name",
    "Draft in time",
    "In target",
    "Days taken (FOIs, IRs, ICO appeals = working days; SARs = calendar days)",
    "Number of days late",
    "Number of days taken after extension",
    "Original internal deadline",
    "Original external deadline",
    "Number of days late against original deadline",
  ].freeze

  CSV_COLUMN_FIELDS = %w[
    number
    case_type
    current_state
    responding_team
    responder
    date_received
    internal_deadline
    external_deadline
    date_responded
    date_compliant_draft_uploaded
    trigger
    name
    requester_type
    message
    info_held
    outcome
    refusal_reason
    exemptions
    postal_address
    email
    appeal_outcome
    third_party
    reply_method
    sar_subject_type
    sar_subject_full_name
    business_unit_responsible_for_late_response
    extended
    extension_count
    deletion_reason
    casework_officer
    created_by
    date_created
    business_group
    directorate_name
    director_general_name
    director_name
    deputy_director_name
    draft_in_time
    in_target
    number_of_days_taken
    number_of_days_late
    number_of_days_taken_after_extension
    original_internal_deadline
    original_external_deadline
    num_days_late_against_original_deadline
  ].freeze

  def initialize(kase)
    @kase = kase
  end

  def to_csv
    [
      @kase.number,
      @kase.decorate.pretty_type,
      @kase.decorate.status,
      @kase.responding_team&.name,
      @kase.responder&.full_name,
      @kase.received_date&.to_s,
      @kase.flagged? ? @kase.internal_deadline&.to_s : nil,
      @kase.external_deadline&.to_s,
      @kase.date_responded&.to_s,
      @kase.date_draft_compliant&.to_s,
      @kase.flagged? ? "Yes" : nil,
      @kase.name,
      @kase.sar? ? nil : @kase.requester_type.humanize,
      dequote_and_truncate(@kase.message),
      @kase.info_held_status&.name,
      @kase.outcome&.name,
      @kase.refusal_reason&.name,
      @kase.exemptions.map { |x| CaseClosure::Exemption.section_number_from_id(x.abbreviation) }.join(","),
      @kase.postal_address,
      @kase.email,
      @kase.appeal_outcome&.name,
      @kase.respond_to?(:third_party) ? humanize_boolean(@kase.third_party) : nil,
      @kase.respond_to?(:reply_method) ? @kase.reply_method.humanize : nil,
      @kase.respond_to?(:subject_type) ? @kase.subject_type.humanize : nil,
      @kase.respond_to?(:subject_full_name) ? @kase.subject_full_name : nil,
      @kase.decorate.late_team_name,
      extension_count(@kase).positive? ? "Yes" : "No",
      extension_count(@kase),
      @kase.reason_for_deletion,
      @kase.casework_officer,
      @kase.creator.full_name,
      @kase.created_at.strftime("%F"), # Date created

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

      # Draft Timliness related information
      humanize_boolean(@kase.within_draft_deadline?), # Draft in time
      humanize_boolean(@kase.response_in_target?), # In Target
      @kase.num_days_taken, # Number of days taken
      @kase.num_days_late, # Number of days late
      @kase.num_days_taken_after_extension, # Number of days late
      @kase.respond_to?(:original_internal_deadline) ? @kase.original_internal_deadline&.to_s : nil,
      @kase.respond_to?(:original_external_deadline) ? @kase.original_external_deadline&.to_s : nil,
      @kase.respond_to?(:original_external_deadline) ? @kase.num_days_late_against_original_deadline : nil,
    ]
  rescue StandardError => e
    raise CSVExporterError, "Error encountered formatting case id #{@kase.id} as CSV:\nOriginal error: #{e.class} #{e.message}"
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/MethodLength,Metrics/CyclomaticComplexity

  def analyse_case(kase)
    @kase = kase
    @kase.to_csv
  end

private

  def extension_count(kase)
    pit_count = 0
    sar_count = 0
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
    text.tr('"', "").tr("'", "")[0..4000]
  end

  def humanize_boolean(boolean)
    boolean ? "Yes" : nil
  end
end

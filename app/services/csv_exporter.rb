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
      'External_deadline',
      'Date responded',
      'Workflow',
      'Name',
      'Requester type',
      'Message',
      'Info_held',
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
      'Extension Days',
  ]

  def initialize(kase)
    @kase = kase
  end

  def to_csv #rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    begin
      [
          @kase.number,
          @kase.decorate.pretty_type,
          @kase.current_state,
          @kase.responding_team&.name,
          @kase.responder&.full_name,
          @kase.received_date&.strftime('%F'),
          @kase.internal_deadline&.strftime('%F'),
          @kase.external_deadline&.strftime('%F'),
          @kase.date_responded.present? ? @kase.date_responded.strftime('%F') : nil,
          @kase.workflow,
          @kase.name,
          @kase.requester_type,
          dequote_and_truncate(@kase.message),
          @kase.info_held_status&.name,
          @kase.outcome&.name,
          @kase.refusal_reason&.name,
          @kase.exemptions.map{ |x| CaseClosure::Exemption.section_number_from_id(x.abbreviation) }.join(','),
          @kase.postal_address,
          @kase.email,
          @kase.appeal_outcome&.name,
          @kase.respond_to?(:third_party) ? @kase.third_party : nil,
          @kase.respond_to?(:reply_method) ? @kase.reply_method : nil,
          @kase.respond_to?(:subject_type) ? @kase.subject_type : nil,
          @kase.respond_to?(:subject_full_name) ? @kase.subject_full_name : nil,
          @kase.decorate.late_team_name,
          (@kase.external_deadline != @kase.initial_deadline) ? 'Yes' : 'No',
          (@kase.external_deadline - @kase.initial_deadline).to_i
      ]
    rescue => err
      raise CSVExporterError.new("Error encountered formatting case id #{@kase.id} as CSV:\nOriginal error: #{err.class} #{err.message}")
    end
  end

  private
  def dequote_and_truncate(text)
    text.tr('"', '').tr("'", '')[0..4000]
  end
end

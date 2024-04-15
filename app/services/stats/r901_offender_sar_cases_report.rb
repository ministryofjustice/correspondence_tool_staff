require "csv"

module Stats
  class R901OffenderSARCasesReport < BaseReport
    CSV_COLUMN_HEADINGS = [
      "Case number",
      "Case type",
      "Nature of the complaint",
      "Priority",
      "Date received at MOJ",
      "Final deadline",
      "Who is dealing with this case",
      "Who is making the request?",
      "Company name",
      "Data subject name",
      "Subject type",
      "Page count",
      "Timeliness (in time/out of time)",
      "Case status",
      "Days open",
      "Data requests completed?",
      "Case originally rejected",
    ].freeze

    def self.title
      "Cases report for Offender SAR and Complaint"
    end

    def self.description
      "The list of Offender SAR and Complaint cases within allowed and filtered scope"
    end

    def initialize(**options)
      super(**options)
      @case_scope = options[:case_scope] || basic_scope
    end

    def case_scope
      @case_scope.where(type: ["Case::SAR::Offender", "Case::SAR::OffenderComplaint"])
    end

    def run(*); end

    def analyse_case(kase)
      [
        kase.number,
        case_type(kase),
        complaint_subtype_for_report(kase),
        kase.offender_sar_complaint? ? kase.priority.humanize : "",
        kase.received_date,
        kase.external_deadline,
        kase.responder.present? ? kase.responder.full_name : "",
        kase.third_party? ? kase.third_party_relationship : "Data subject",
        kase.third_party_company_name,
        kase.subject_full_name,
        I18n.t("helpers.label.offender_sar.subject_type.#{kase.subject_type}"),
        kase.page_count,
        kase.already_late? ? "out of time" : "in time",
        kase.current_state.humanize,
        kase.num_days_taken,
        kase.data_requests_completed? ? "Yes" : "No",
        kase.case_originally_rejected ? "Yes" : "No",
      ]
    end

    def to_csv
      CSVGenerator.new(case_scope, self)
    end

    def report_type
      ReportType.r901
    end

  private

    def basic_scope
      # As the Complaint class is inheried from Offender, so the following will return both type cases
      # which may cause issue in the future if we change the hierarchy of offender related classes
      Case::SAR::Offender.all
    end

    def complaint_subtype_for_report(kase)
      kase.offender_sar_complaint? ? kase.complaint_subtype.humanize : ""
    end

    def case_type(kase)
      kase.decorate.pretty_type
    end
  end
end

module CommissioningDocumentTemplate
  class Base
    attr_reader :data_request_area, :deadline

    delegate :kase, to: :data_request_area

    def initialize(data_request_area:, deadline:)
      @data_request_area = data_request_area.decorate
      @deadline = date_format(deadline)
    end

    def path
      Rails.root.join("lib", "assets", template_name)
    end

    def context
      {
        dpa_reference: kase.number,
        offender_name: kase.subject_full_name,
        date_of_birth: date_format(kase.date_of_birth),
        date: today,
        deadline:,
        prison_numbers: kase.prison_number,
      }
    end

  private

    def template_name
      "#{self.class.name.demodulize.underscore}.docx"
    end

    def today
      date_format(Date.current)
    end

    def date_format(date)
      date&.strftime("%d/%m/%Y")
    end
  end
end

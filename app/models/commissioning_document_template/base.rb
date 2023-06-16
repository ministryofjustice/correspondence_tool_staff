module CommissioningDocumentTemplate
  class Base
    attr_reader :data_request

    delegate :kase, to: :data_request

    def initialize(data_request:)
      @data_request = data_request.decorate
    end

    def path
      Rails.root.join('lib', 'assets', template_name)
    end

    def context
      {
        dpa_reference: kase.number,
        offender_name: kase.subject_full_name,
        date_of_birth: date_format(kase.date_of_birth),
        date: today,
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

    def calculate_deadline(count)
      date_format(Date.current + count.days)
    end

    def date_format(date)
      date.strftime('%d/%m/%Y')
    end
  end
end

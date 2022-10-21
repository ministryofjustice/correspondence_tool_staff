module DocumentTemplate
  class Base
    DOCUMENT_TEMPLATE_TYPE = {
      prison_records: 0,
      security: 1,
      probation: 2,
      cctv: 3,
      mappa: 4,
      cat_a: 5
    }.freeze

    attr_reader :data_request

    delegate :kase, to: :data_request

    def initialize(data_request:)
      @data_request = data_request
    end

    def path
      Rails.root.join('lib', 'assets', template_name)
    end

    private

    def today
      date_format(Date.current)
    end

    def deadline(count)
      date_format(Date.current + count.days)
    end

    def date_format(date)
      date.strftime("%d/%m/%Y")
    end
  end
end

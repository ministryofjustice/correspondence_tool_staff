module DocumentTemplate
  class Base
    DOCUMENT_TEMPLATE_TYPE = {
      prison_records: 0
    }

    attr_reader :data_request

    def initialize(data_request:)
      @data_request = data_request
    end

    def kase
      data_request.kase
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

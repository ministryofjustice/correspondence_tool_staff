class DocumentTemplateService
  class InvalidDataRequestError < RuntimeError
    def initialize
      super("data request is invalid")
    end
  end

  class InvalidTemplateError < RuntimeError
    def initialize
      super("template type is invalid")
    end
  end

  def initialize(data_request:, template_type:)
    @data_request = data_request
    @template_type = template_type

    raise InvalidDataRequestError.new unless @data_request.is_a?(DataRequest)
    raise InvalidTemplateError.new unless DocumentTemplate::Base::DOCUMENT_TEMPLATE_TYPES.include?(@template_type)
  end

  def context
    template.context
  end

  private

  def template
    klass = Object.const_get("#{DocumentTemplate}::#{@template_type.to_s.classify}")
    @template ||= klass.new(data_request: @data_request)
  end
end

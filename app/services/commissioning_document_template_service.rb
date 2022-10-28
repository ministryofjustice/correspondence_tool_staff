class CommissioningDocumentTemplateService
  attr_reader :result, :document, :filename, :mime_type

  def initialize(data_request:, template_type:)
    @data_request = data_request
    @template_type = template_type
  end

  def call
    if template.nil? || !@data_request.is_a?(DataRequest)
      @result = :error
      return
    end

    set_filename
    @document = Sablon.template(template.path).render_to_string(template.context)
    @mime_type = :docx
    @result = :ok
  end

  private

  def set_filename
    number = @data_request.kase.number
    name = @data_request.kase.subject_full_name.tr(' ', '-')
    timestamp = Time.current.strftime('%Y%m%dT%H%M')
    type = CommissioningDocument::TEMPLATE_TYPES[@template_type]
    @filename = "Day1_#{type}_#{number}_#{name}_#{timestamp}.docx"
  end

  def template
    @template ||= begin
      klass = Object.const_get("#{CommissioningDocumentTemplate}::#{@template_type.to_s.classify}")
      klass.new(data_request: @data_request)
    rescue
      nil
    end
  end
end

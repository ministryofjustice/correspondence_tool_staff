class CommissioningDocumentDecorator < Draper::Decorator
  include ActionView::Helpers::UrlHelper

  delegate_all

  def sent?
    super ? 'Yes': 'No'
  end

  def request_document
    I18n.t("helpers.label.commissioning_document.template_name.#{template_name}")
  end

  def updated_at
    I18n.l(super, format: :default)
  end

  def download_link
    link_to('Download', h.download_case_data_request_commissioning_document_path(self.data_request.case_id, self.data_request, self))
  end

  def replace_link
    link_to('Replace', h.upload_case_data_request_commissioning_document_path(self.data_request.case_id, self.data_request, self))
  end
end

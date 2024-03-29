class CommissioningDocumentDecorator < Draper::Decorator
  include ActionView::Helpers::UrlHelper

  delegate_all

  def request_document
    I18n.t("helpers.label.commissioning_document.template_name.#{template_name}")
  end

  def updated_at
    I18n.l(super, format: :default)
  end

  def download_link
    link_to("Download", h.download_case_data_request_commissioning_document_path(data_request.case_id, data_request, self))
  end

  def replace_link
    link_to("Replace", h.replace_case_data_request_commissioning_document_path(data_request.case_id, data_request, self))
  end

  def change_link
    link_to("Change", h.edit_case_data_request_commissioning_document_path(data_request.case_id, data_request, self))
  end
end

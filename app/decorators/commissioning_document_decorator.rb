class CommissioningDocumentDecorator < Draper::Decorator
  include ActionView::Helpers::UrlHelper

  delegate_all

  def request_document
    I18n.t("helpers.label.commissioning_document.stage.day_1")
    # TODO: dynamically choose stage value during chase work
    # such as I18n.t("helpers.label.commissioning_document.stage.#{stage}")
  end

  def updated_at
    I18n.l(super, format: :default)
  end

  def download_link
    if data_request_area.offender_sar_case.readonly?
      I18n.t("cases.data_request_areas.show.document_deleted")
    else
      link_to("Download", h.download_case_data_request_area_commissioning_documents_path(data_request_area.case_id, data_request_area, self))
    end
  end
end

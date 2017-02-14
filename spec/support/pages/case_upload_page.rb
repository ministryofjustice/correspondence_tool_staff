class CaseUploadPage < SitePrism::Page
  set_url '/cases/{id}/new_response_upload'

  element :file_fields, '#attachment_url'
end

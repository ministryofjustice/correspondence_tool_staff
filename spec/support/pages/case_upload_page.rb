class CaseUploadPage < SitePrism::Page
  set_url '/cases/{id}/new_response_upload'

  element :file_fields, '#attachment_url'
  section :existing_files, 'table#uploaded-files tr' do
    element :filename, 'td[aria-label="File name"]'
  end
end

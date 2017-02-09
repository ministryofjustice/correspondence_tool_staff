module CasesHelper
  def accepted_case_attachment_types
    Settings.case_uploads_accepted_types.join ','
  end

  def attachment_filename(url)
    URI.decode(
      File.basename(
        URI.parse(url).path
      )
    )
  rescue
    url
  end
end

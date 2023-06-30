module CaseAttachmentParams
  extend ActiveSupport::Concern

  def create_params
    params.permit(
      :upload_comment,
      uploaded_request_files: [],
    )
  end
end

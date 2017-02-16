class CaseAttachmentsController < ApplicationController
  before_action :set_case,       only: [:download]
  before_action :set_attachment, only: [:download]

  def download
    redirect_to @attachment.url
  end

  private

  def set_attachment
    @attachment = @case.attachments.find(params[:id])
  end

  def set_case
    @case = Case.find(params[:case_id])
  end
end

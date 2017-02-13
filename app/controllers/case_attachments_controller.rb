class CaseAttachmentsController < ApplicationController
  before_action :set_case,       only: [:destroy, :download]
  before_action :set_attachment, only: [:destroy, :download]

  def download
    redirect_to @attachment.url
  end

  def destroy
    @attachment.destroy!
  end

  private

  def set_attachment
    @attachment = @case.attachments.find(params[:id])
  end

  def set_case
    @case = Case.find(params[:case_id])
  end
end

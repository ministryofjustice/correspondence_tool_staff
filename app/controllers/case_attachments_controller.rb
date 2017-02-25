class CaseAttachmentsController < ApplicationController
  before_action :set_case,       only: [:destroy, :download]
  before_action :set_attachment, only: [:destroy, :download]

  def download
    redirect_to @attachment.temporary_url
  end

  def destroy
    authorize @case, :can_add_attachment?

    @attachment.destroy!
    respond_to do |format|
      format.js
      format.html { redirect_to case_path(@case) }
    end
  end

  private

  def set_attachment
    @attachment = @case.attachments.find(params[:id])
  end

  def set_case
    @case = Case.find(params[:case_id])
  end
end

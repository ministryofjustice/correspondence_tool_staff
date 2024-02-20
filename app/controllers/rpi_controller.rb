class RpiController < ApplicationController
  before_action :get_request, :get_target

  def download
    @request.last_accessed_at = Time.current
    @request.last_accessed_by = current_user.id
    @request.save!

    redirect_to @request.temporary_url(@target)
  end

  def get_request
    @request = PersonalInformationRequest.find_by!(submission_id: params[:id])
  end

  def get_target
    @target = params[:target]
    unless PersonalInformationRequest.valid_target?(@target)
      raise ActiveRecord::RecordNotFound
    end
  end
end

class RpiController < ApplicationController
  before_action :get_request

  def download
    @request.last_accessed_at = Time.current
    @request.last_accessed_by = current_user.id
    @request.save!

    redirect_to @request.temporary_url
  end

  def get_request
    @request = PersonalInformationRequest.find_by!(submission_id: params[:id])
  end
end

class RpiController < ApplicationController
  before_action :get_request

  def download
    redirect_to @request.temporary_url
  end

  def get_request
    @request = PersonalInformationRequest.find_by!(submission_id: params[:id])
  end
end

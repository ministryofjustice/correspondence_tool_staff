module Cases
  class DataRequestsController < ApplicationController
    DEFAULT_DATA_REQUESTS = 3

    before_action :set_case, only: [:new, :create]

    def index
    end

    def show
    end

    def new
      authorize @case, :can_record_data_request?
      DEFAULT_DATA_REQUESTS.times { @case.data_requests.build }
    end

    def create
      authorize @case, :can_record_data_request?

      service = DataRequestService.new(
        kase: @case,
        user: current_user,
        data_requests: permitted_params[:data_requests_attributes]
      )
      service.call

      if service.result == :ok
        flash[:notice] = t('.success')
        redirect_to new_case_data_request_path(@case)
      else
        @case = service.case
        render :new
      end
    end

    def update
    end

    def destroy
    end


    private

    def set_case
      @case = Case::Base.find(params[:case_id])
    end

    def permitted_params
      params.require(:case).permit(data_requests_attributes: [:location, :data])
    end
  end
end

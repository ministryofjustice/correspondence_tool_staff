module Cases
  class DataRequestsController < ApplicationController
    before_action :set_case, only: [:new, :create]

    def index
    end

    def show
    end

    def new
      authorize @case, :can_record_data_request?
      @data_request = DataRequest.new
    end

    def create
      authorize @case, :can_record_data_request?

      service = DataRequestService.new(
        kase: @case,
        user: current_user,
        params: permitted_params
      )
      service.call

      if service.result == :ok
        flash[:notice] = t('.success')
        redirect_to new_case_data_request_path(@case)
      else
        @data_request = service.data_request
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
      params.require(:data_request).permit(:location, :data)
    end
  end
end

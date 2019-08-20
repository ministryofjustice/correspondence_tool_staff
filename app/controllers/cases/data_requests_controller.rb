module Cases
  class DataRequestsController < ApplicationController
    NUM_NEW_DATA_REQUESTS = 3

    before_action :set_case, only: [:new, :create]

    def index
    end

    def show
    end

    def new
      authorize @case, :can_record_data_request?

      # Explicitly created DataRequest as an array rather than performing
      # 3.times { @case.data_requests.new } to ensure the partial _data_request
      # form.index is correct (rather than including existing data requests)
      @data_requests = Array.new(NUM_NEW_DATA_REQUESTS, DataRequest.new)
    end

    def create
      authorize @case, :can_record_data_request?

      service = DataRequestService.new(
        kase: @case,
        user: current_user,
        data_requests: permitted_params[:data_requests_attributes]
      )
      service.call

      case service.result
      when :ok
        flash[:notice] = t('.success')
        redirect_to case_path(@case)
      when :unprocessed
        flash[:alert] = t('.unprocessed')
        redirect_to new_case_data_request_path(@case)
      when :error
        @case = service.case
        @data_requests = service.new_data_requests
        render :new
      else
        raise ArgumentError.new("Unknown result: #{service.result.inspect}")
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

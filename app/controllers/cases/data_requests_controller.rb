module Cases
  class DataRequestsController < ApplicationController
    NUM_NEW_DATA_REQUESTS = 3

    before_action :set_case
    before_action :set_data_request, only: [:edit, :update, :destroy]
    before_action :authorize_action
    after_action  :verify_authorized

    def new
      # Explicitly created DataRequest as an array rather than performing
      # 3.times { @case.data_requests.new } to ensure the partial _data_request
      # form.index is correct (rather than including existing data requests)
      @data_requests = Array.new(NUM_NEW_DATA_REQUESTS, DataRequest.new)
    end

    def create
      service = DataRequestCreateService.new(
        kase: @case,
        user: current_user,
        data_requests: create_params[:data_requests_attributes]
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

    def edit
      # When editing a DataRequest we are creating a new DataRequestLog with
      # the new user-entered values denormalized and saved in the
      # DataRequest#cached_ attributes
      @data_request_log = @data_request.new_log
    end

    def update
      service = DataRequestUpdateService.new(
        user: current_user,
        data_request: @data_request,
        params: update_params
      )
      service.call

      case service.result
      when :ok
        flash[:notice] = t('.success')
        redirect_to case_path(@case)
      when :unprocessed
        flash[:notice] = t('.unprocessed')
        redirect_to edit_case_data_request_path(@case, @data_request)
      when :error
        @data_request_log = service.data_request_log
        render :edit
      else
        raise ArgumentError.new("Unknown result: #{service.result.inspect}")
      end
    end

    def destroy
      raise NotImplementedError.new 'Data request delete unavailable'
    end


    private

    def set_case
      @case = Case::Base.find(params[:case_id])
    end

    def set_data_request
      @data_request = DataRequest.find(params[:id])
    end

    def create_params
      params.require(:case).permit(data_requests_attributes: [:location, :request_type])
    end

    def update_params
      params.require(:data_request_log).permit(
        :date_received_dd, :date_received_mm, :date_received_yyyy,
        :num_pages
      )
    end

    def authorize_action
      authorize @case, :can_record_data_request?
    end
  end
end

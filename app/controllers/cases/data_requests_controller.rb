module Cases
  class DataRequestsController < ApplicationController
    NUM_NEW_DATA_REQUESTS = 3

    before_action :set_case
    before_action :set_data_request, only: [:show, :edit, :update, :destroy, :send_email]
    before_action :set_commissioning_document, only: [:show, :send_email]
    before_action :authorize_action
    after_action  :verify_authorized

    def new
      @data_request = DataRequest.new
    end

    def create
      service = DataRequestCreateService.new(
        kase: @case,
        user: current_user,
        data_request_params: create_params
      )
      service.call

      case service.result
      when :ok
        flash[:notice] = t('.success')
        redirect_to case_path(@case)
      when :error
        @case = service.case
        @data_request = service.data_request
        render :new
      else
        raise ArgumentError.new("Unknown result: #{service.result.inspect}")
      end
    end

    def show
    end

    def edit
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
        redirect_to case_path(@case)
      when :error
        @data_request = service.data_request
        render :edit
      else
        raise ArgumentError.new("Unknown result: #{service.result.inspect}")
      end
    end

    def destroy
      raise NotImplementedError.new 'Data request delete unavailable'
    end

    def send_email
    end

    def probation_send_email
    end

    private

    def set_case
      @case = Case::Base.find(params[:case_id])
    end

    def set_data_request
      @data_request = DataRequest.find(params[:id]).decorate
    end

    def set_commissioning_document
      @commissioning_document = @data_request.commissioning_document&.decorate
    end

    def create_params
      params.require(:data_request).permit(
        :location,
        :contact_id,
        :request_type,
        :request_type_note,
        :date_requested_dd, :date_requested_mm, :date_requested_yyyy,
        :date_from_dd, :date_from_mm, :date_from_yyyy,
        :cached_date_received_dd, :cached_date_received_mm, :cached_date_received_yyyy,
        :date_to_dd, :date_to_mm, :date_to_yyyy,
      )
    end

    def update_params
      params.require(:data_request).permit(
        :location,
        :contact_id,
        :request_type,
        :request_type_note,
        :date_requested_dd, :date_requested_mm, :date_requested_yyyy,
        :date_from_dd, :date_from_mm, :date_from_yyyy,
        :date_to_dd, :date_to_mm, :date_to_yyyy,
        :cached_num_pages,
        :cached_date_received_dd, :cached_date_received_mm, :cached_date_received_yyyy,
        :completed
      )
    end

    def authorize_action
      authorize @case, :can_record_data_request?
    end
  end
end

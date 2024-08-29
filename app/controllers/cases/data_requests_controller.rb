module Cases
  class DataRequestsController < ApplicationController
    NUM_NEW_DATA_REQUESTS = 3

    before_action :set_case
    before_action :set_data_request_area
    before_action :set_data_request, only: %i[show edit update destroy]
    before_action :authorize_action
    after_action  :verify_authorized

    def new
      @data_request = DataRequest.new(
        data_request_area: @data_request_area
      )
    end

    def create
      service = DataRequestCreateService.new(
        kase: @case,
        user: current_user,
        data_request_area: @data_request_area,
        data_request_params: create_params,
      )

      service.call

      case service.result
      when :ok
        flash[:notice] = t(".success")
        redirect_to case_data_request_area_path(@case, @data_request_area)
      when :error
        @case = service.case
        @data_request = service.data_request
        render :new
      else
        raise ArgumentError, "Unknown result: #{service.result.inspect}"
      end
    end

    def show; end

    def edit; end

    def update
      service = DataRequestUpdateService.new(
        user: current_user,
        data_request: @data_request,
        params: update_params,
      )
      service.call

      case service.result
      when :ok
        flash[:notice] = t(".success")
        redirect_to case_data_request_area_path(@case, @data_request_area)
      when :unprocessed
        flash[:notice] = t(".unprocessed")
        redirect_to case_data_request_area_path(@case, @data_request_area)
      when :error
        @data_request = service.data_request
        render :edit
      else
        raise ArgumentError, "Unknown result: #{service.result.inspect}"
      end
    end

    def destroy
      raise NotImplementedError, "Data request delete unavailable"
    end

    def send_email
      @recipient_emails = @data_request.recipient_emails

      @no_email_present = @recipient_emails.empty?

      if @commissioning_document.probation? && !handled_sending_to_branston_archives?
        render :probation_send_email and return
      end
    end

  private

    def handled_sending_to_branston_archives?
      if request.get?
        @email = ProbationCommissioningDocumentEmail.new
        return false
      end

      @email = ProbationCommissioningDocumentEmail.new(email_params)
      return false unless @email.valid?

      if @email.email_branston_archives == "yes"
        @data_request.update!(email_branston_archives: true)
        @recipient_emails << CommissioningDocumentTemplate::Probation::BRANSTON_ARCHIVES_EMAIL
      end

      true
    end

    def set_case
      @case = Case::Base.find(params[:case_id])
    end

    def set_data_request
      @data_request = @data_request_area.data_requests.find(params[:id])
    end

    def set_data_request_area
      @data_request_area = @case.data_request_areas.find(params[:data_request_area_id])
    end

    def email_params
      params.require(:probation_commissioning_document_email).permit(:email_branston_archives)
    end

    def create_params
      params.require(:data_request).permit(
        :request_type,
        :request_type_note,
        :date_requested_dd, :date_requested_mm, :date_requested_yyyy,
        :date_from_dd, :date_from_mm, :date_from_yyyy,
        :cached_date_received_dd, :cached_date_received_mm, :cached_date_received_yyyy,
        :date_to_dd, :date_to_mm, :date_to_yyyy
      )
    end

    def update_params
      params.require(:data_request).permit(
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
      if action_name == "show"
        authorize @case, :show?
      else
        authorize @case, :can_record_data_request?
      end
    end
  end
end

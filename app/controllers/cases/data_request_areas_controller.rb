module Cases
  class DataRequestAreasController < ApplicationController
    before_action :set_case
    before_action :set_data_request_area, only: %i[show destroy send_email]
    before_action :set_commissioning_document, only: %i[show send_email]
    before_action :authorize_action

    def new
      @data_request_area = DataRequestArea.new
    end

    def create
      service = DataRequestAreaCreateService.new(
        kase: @case,
        user: current_user,
        data_request_area_params: create_params,
      )
      service.call

      @data_request_area = service.data_request_area

      case service.result
      when :ok
        flash[:notice] = t(".success")
        redirect_to case_data_request_area_path(@case, @data_request_area)
      when :error
        render :new
      else
        raise ArgumentError, "Unknown result: #{service.result.inspect}"
      end
    end

    def show; end

    def destroy
      if @data_request_area.data_requests.exists?
        redirect_to case_path(@case), notice: "Data request area cannot be destroyed because it has associated data requests."
      else
        @data_request_area.destroy!
        redirect_to case_path(@case), notice: "Data request was successfully destroyed."
      end
    end

    def send_email
      @recipient_emails = @data_request_area.recipient_emails

      @no_email_present = @recipient_emails.empty?

      # if @commissioning_document.probation? && !handled_sending_to_branston_archives?
      #   render :probation_send_email and return
      # end
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

    def set_data_request_area
      @data_request_area = @case.data_request_areas.find(params[:id]).decorate
    end

    def set_commissioning_document
      @commissioning_document = @data_request_area.commissioning_document&.decorate
    end

    def create_params
      params.require(:data_request_area).permit(:data_request_area_type, :location, :contact_id)
    end

    def email_params
      params.require(:probation_commissioning_document_email).permit(:email_branston_archives)
    end

    def authorize_action
      case action_name
      when "show"
        authorize @case, :show?
      else
        authorize @case, :can_record_data_request?
      end
    end
  end
end

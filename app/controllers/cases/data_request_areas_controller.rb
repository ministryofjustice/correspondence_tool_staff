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

    def show
      @request_ready = @data_request_area.status == :completed
    end

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
    end

  private

    def set_case
      @case = Case::Base.find(params[:case_id])
    end

    def set_data_request_area
      @data_request_area = @case.data_request_areas.find(params[:id]).decorate
    end

    def set_commissioning_document
      @data_request_area.commissioning_document = build_commissioning_document
    end

    def create_params
      params.require(:data_request_area).permit(:data_request_area_type, :location, :contact_id)
    end

    def build_commissioning_document
      template_class = case @data_request_area.data_request_area_type
                       when "mappa"
                         CommissioningDocumentTemplate::Mappa
                       else
                         CommissioningDocumentTemplate::Standard
                       end

      @commissioning_document = CommissioningDocument.find_or_initialize_by(data_request_area: @data_request_area).decorate
      @commissioning_document.template_name = template_class.name.demodulize.underscore
      @commissioning_document
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

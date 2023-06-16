module Cases
  class OffenderSarComplaintController < OffenderSarController
    before_action -> { set_decorated_case(params[:id]) }, only: %i[
      reopen confirm_reopen
    ]

    include OffenderSARComplaintCasesParams

    def initialize
      super

      @correspondence_type = CorrespondenceType.offender_sar_complaint
      @correspondence_type_key = "offender_sar_complaint"
      @creation_optional_flags = { flag_for_creation_from_sar_page: 0 }
    end

    def start_complaint
      params.merge!(current_step: "link-offender-sar-case", flag_for_creation_from_sar_page: true)
      params.merge!(commit: true)
      params[@correspondence_type_key] = {}
      params[@correspondence_type_key].merge!("original_case_number" => params["number"])
      create!
    end

    def reopen
      authorize @case, :can_be_reopened?
      if @case.standard_complaint?
        @case.received_date = Date.today
        @case.object.external_deadline = @case.object.deadline_calculator.external_deadline
      end
      render :reopen
    end

    def confirm_reopen
      authorize @case, :can_be_reopened?

      @case.assign_attributes(reopen_offender_sar_complaint_params)
      if @case.valid?
        service = CaseReopenService.new(
          current_user,
          @case,
          reopen_offender_sar_complaint_params,
        )
        service.call

        if service.result == :ok
          flash[:notice] = "You have reopened case #{@case.number}."
          redirect_to case_path(@case) and return
        end
      end
      render :reopen
    end

    def set_case_types
      @case_types = ["Case::SAR::OffenderComplaint"]
    end

    def case_type
      Case::SAR::OffenderComplaint
    end

    def create_params
      create_offender_sar_complaint_params
    end

    def edit_params
      if params[:offender_sar_complaint].present?
        clean_empty_approval_flags(create_offender_sar_complaint_params)
      else
        {}
      end
    end

    def update_params
      create_offender_sar_complaint_params
    end

    def process_closure_params
      process_offender_sar_complaint_closure_params
    end

    def process_date_responded_params
      respond_offender_sar_complaint_params
    end

    def session_state
      "#{@correspondence_type_key}_state".to_sym
    end

    def case_updater_service
      # overides base class method to utilise specific
      # service in complaint case updates
      ComplaintCaseUpdaterService
    end

  private

    def clean_empty_approval_flags(permitted_params)
      if permitted_params["approval_flag_ids"].present?
        permitted_params["approval_flag_ids"].delete("")
      end
      permitted_params
    end

    def back_link_url
      if has_optional_flags? && @case.current_step == "confirm-offender-sar"
        case_path @case.original_case.id
      else
        super
      end
    end
  end
end

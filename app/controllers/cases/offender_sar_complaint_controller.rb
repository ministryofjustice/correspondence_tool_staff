module Cases
  class OffenderSarComplaintController < OffenderSarController

    before_action -> { set_decorated_case(params[:id]) }, only: [
      :reopen, :confirm_reopen
    ]

    include OffenderSARComplaintCasesParams

    def initialize
      super

      @correspondence_type = CorrespondenceType.offender_sar_complaint
      @correspondence_type_key = 'offender_sar_complaint'
    end

    def start_complaint
      params.merge!(:current_step => "link-offender-sar-case")
      params.merge!(:commit => true)
      params[@correspondence_type_key] = {}
      params[@correspondence_type_key].merge!("original_case_number" => params["number"])
      create
    end

    def reopen
      authorize @case, :can_be_reopened?
      if request.get?
        if @case.standard_complaint?
          @case.received_date = Date.today
          @case.object.external_deadline = @case.object.deadline_calculator.external_deadline
        end
        render :reopen
      else
        confirm_reopen
      end
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
      create_offender_sar_complaint_params
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

    private 

    def confirm_reopen
      @case.assign_attributes(reopen_offender_sar_complaint_params)
      if @case.valid?
        service = CaseReopenService.new(
          current_user,
          @case,
          reopen_offender_sar_complaint_params
        )
        service.call
    
        if service.result == :ok
          flash[:notice] = "You have reopened case #{@case.number}."
          redirect_to case_path(@case) and return 
        end
      end
      render :reopen
    end

  end
end

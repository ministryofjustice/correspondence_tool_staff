module Cases
  class OffenderSarController < BaseController
    include NewCase
    include OffenderSARCasesParams

    def initialize
      @correspondence_type = CorrespondenceType.offender_sar
      @correspondence_type_key = 'offender'

      super
    end

    def new
      permitted_correspondence_types
      set_correspondence_type(params[:correspondence_type])
      prepare_new_case

      @case = OffenderSARCaseForm.new(session)
      @case.current_step = params[:step]
    end

    def create
      permitted_correspondence_types
      set_correspondence_type(params[:correspondence_type])
      prepare_new_case

      @case = OffenderSARCaseForm.new(session)

      @case.case.creator = current_user #to-do Remove when we use the case create service
      @case.case.subject = "Offender SAR" #to-do Remove when we use the case create service

      @case.assign_params(case_params) if case_params
      @case.current_step = params[:current_step]

      if @case.valid_attributes?(case_params)
        if @case.valid?
          if @case.save
            session[:offender_sar_state] = nil
            redirect_to case_path(@case.case) and return
          end
        end
        @case.session_persist_state(case_params)
        get_next_step(@case)
        redirect_to offender_sar_new_case_path + "/#{@case.current_step}"
      else
        render :new
      end
    end

    def case_type
      Case::SAR::Offender
    end

    def create_params
      create_offender_sar_params
    end

    def edit_params
      edit_offender_sar_params
    end


    def cancel
      session[:offender_sar_state] = nil
      redirect_to offender_sar_new_case_path
    end

    private

    def get_next_step(obj)
      obj.current_step = params[:current_step]

      if params[:previous_button]
        obj.previous_step
      elsif params[:commit]
        obj.next_step
      end
    end

    def get_step_partial(current_step)
      step_name = current_step.split('/').first.tr('-', '_')
      "#{step_name}_step"
    end
  end
end

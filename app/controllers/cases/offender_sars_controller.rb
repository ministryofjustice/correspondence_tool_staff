class Cases::OffenderSarsController < CasesController
  def new
    permitted_correspondence_types
    set_correspondence_type(params[:correspondence_type])
    prepare_new_case

    @case = OffenderSARCaseForm.new(@case, params, session)
    @case.current_step = params[:step]
  end

  def create
    permitted_correspondence_types
    set_correspondence_type(params[:correspondence_type])
    prepare_new_case

    @case = OffenderSARCaseForm.new(@case, params, session)
    if @case.valid_params? # TODO - verify the submitted information is valid
      @case.session_persist_state
      get_next_step(@case)
      redirect_to offender_sar_new_case_path + "/#{@case.current_step}"
    end
  end

  private

  def prepare_new_case
    valid_type = validate_correspondence_type(params[:correspondence_type].upcase)
    if valid_type == :ok
      set_correspondence_type(params[:correspondence_type])
      default_subclass = @correspondence_type.sub_classes.first

      authorize default_subclass, :can_add_case?

      @case = default_subclass.new.decorate
      @case_types = @correspondence_type.sub_classes.map(&:to_s)
      @s3_direct_post = s3_uploader_for(@case, 'requests')
    else
      flash.alert =
          helpers.t "cases.new.correspondence_type_errors.#{valid_type}",
                    type: @correspondence_type_key
      redirect_to new_case_path
    end
  end

  def get_next_step(obj)
    obj.current_step = params[:current_step]
    if params[:previous_button]
      obj.previous_step
    elsif params[:commit]
      obj.next_step
    end
  end

  def get_step_partial(current_step)
    step_name = current_step.split("/").first.tr('-', '_')
    "#{step_name}_step"
  end
end

class Cases::OffenderSarsController < CasesController
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

    @case.assign_params(case_params) if case_params

    if @case.valid_attributes?(case_params)
      @case.session_persist_state(case_params)
      get_next_step(@case)
      redirect_to offender_sar_new_case_path + "/#{@case.current_step}"
    else
      render :new
    end
  end

  def cancel
    session[:offender_sar_state] = nil
    redirect_to offender_sar_new_case_path
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

  def case_params
    params.require(:offender_sar_case_form).permit(:name, :email, :message, :subject_full_name, :prison_number, :subject_aliases, :previous_case_numbers, :other_subject_ids, :date_of_birth_dd, :date_of_birth_mm, :date_of_birth_yyyy, :subject_type, :flag_for_disclosure_specialists, :third_party, :name, :third_party_relationship, :postal_address, :received_date_dd, :received_date_mm, :received_date_yyyy) if params[:offender_sar_case_form].present?
  end
end

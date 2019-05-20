class Cases::OffenderSarsController < CasesController

  def new
    permitted_correspondence_types
    set_correspondence_type(params[:correspondence_type])
    prepare_new_case
    @case.current_step = params[:step]
  end

  def create
    permitted_correspondence_types
    set_correspondence_type(params[:correspondence_type])
    prepare_new_case
    if @case # the submitted information is valid
      get_next_step(@case)
      redirect_to osar_new_case_path + "/#{@case.current_step}"
    end
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
    step_name = current_step.split("/").first.tr('-', '_')
    "#{step_name}_step"
  end
end

class Cases::OffenderSarsController < CasesController

  def new
    permitted_correspondence_types
    set_correspondence_type(params[:correspondence_type])
    prepare_new_case
    @case.current_step = params[:step]
  end

  def create

  end

  private

  def get_step_partial(current_step)
    step_name = current_step.split("/").first.gsub('-', '_')
    "#{step_name}_step"
  end
end

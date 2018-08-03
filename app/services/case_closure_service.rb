class CaseClosureService

  def initialize(kase, params)
    @kase = kase
    @params = params
  end

  def call
    #
    #   @case.prepare_for_close
    #   close_params = process_closure_params(@case.type_abbreviation)
    #   if @case.update(close_params)
    #     @case.close(current_user)
    #     set_permitted_events
    #     flash[:notice] = t('notices.case_closed')
    #     redirect_to case_path(@case)
    #   else
    #     set_permitted_events
    #     render :close
    #   end
    # end

    @case.prepare_for_close
    if @case.update(@params)
      @flash = I18n.t('notices.case_closed')
    else
    self
  end



end

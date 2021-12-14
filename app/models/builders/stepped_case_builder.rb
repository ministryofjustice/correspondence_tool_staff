module Builders
  class SteppedCaseBuilder
    attr_reader :kase

    def initialize(case_type:, session:, step:, creator:, params: nil)
      @case_type = case_type
      @session   = session
      @step    = step
      @creator   = creator
      @params = params

      @ready_for_creation = false
      @kase = nil
    end

    def build
      build_from_session
      set_creator_from_user
      set_current_step
      finalize_build_if_steps_complete
      @kase
    end

    def kase_ready_for_creation?
      @ready_for_creation
    end

    private

    def build_from_session
      values = @session[session_state] 
      @kase = @case_type.new(values).decorate
    end

    def set_creator_from_user
      @kase.creator = @creator
    end

    def set_current_step
      @kase.current_step = @step
    end

    def finalize_build_if_steps_complete
      if @kase.steps_are_completed? && @params.present?
        @kase.assign_attributes(@params)
        if @kase.valid?
          @ready_for_creation = true
        end
      end
    end

    def session_state
      "#{@case_type.type_abbreviation.downcase}_state"
    end
  end
end

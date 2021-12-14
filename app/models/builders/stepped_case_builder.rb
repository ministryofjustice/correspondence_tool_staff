module Builders

  class CaseNotBuiltYetError < StandardError
  end

  class SteppedCaseBuilder
    attr_reader :kase

    def initialize(case_type:, session:, params:, creator:)
      @case_type = case_type
      @session   = session
      @params    = params
      @creator   = creator

      @kase = nil
    end

    def build_from_session
      values = @session[session_state] 
      @kase = @case_type.new(values).decorate
    end

    def set_creator_from_user
      @kase.creator = @creator
    end

    def set_initial_step
      @kase.current_step = @params[:step]
    end

    def set_current_step
      @kase.current_step = @params[:current_step]
    end

    private

    def session_state
      "#{@case_type.type_abbreviation.downcase}_state"
    end

  end
end

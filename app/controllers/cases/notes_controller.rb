module Cases
  class NotesController < ApplicationController
    include Notable
    include GovUKDateFixes

    before_action :set_case, :set_date_of_birth

    def create
      authorize(@case, :can_add_note_to_case?)

      add_message(
        event_name: 'add_note_to_case!',
        on_success: case_path(@case, anchor: 'case-history')
      )
    end
  end
end

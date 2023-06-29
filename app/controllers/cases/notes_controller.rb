module Cases
  class NotesController < ApplicationController
    include Notable

    before_action :set_case

    def create
      authorize(@case, :can_add_note_to_case?)

      add_message(
        event_name: "add_note_to_case!",
        on_success: case_path(@case, anchor: "case-history"),
      )
    end
  end
end

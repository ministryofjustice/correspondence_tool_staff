module Cases
  class MessagesController < ApplicationController
    include Notable

    before_action :set_case

    def create
      authorize(@case, :can_add_message_to_case?)

      add_message(
        event_name: "add_message_to_case!",
        on_success: case_path(@case, anchor: "messages-section"),
      )
    end
  end
end

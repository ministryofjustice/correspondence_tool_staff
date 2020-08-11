class DataRequestCreateService
  attr_reader :result, :case, :new_data_requests

  def initialize(kase:, user:, data_requests:)
    @result = nil
    @user = user
    @case = kase
    @new_data_requests = build_data_requests(data_requests)
  end

  def call
    ActiveRecord::Base.transaction do
      begin
        @result = :unprocessed
        return if @new_data_requests.empty?

        @case.save!

        if @case.allow_waiting_for_data_state?
          @case.state_machine.mark_as_waiting_for_data!(
            acting_user: @user,
            acting_team: BusinessUnit.dacu_branston,
          )
        end

        @result = :ok
     rescue ActiveRecord::RecordInvalid, ActiveRecord::AssociationTypeMismatch
       @result = :error
      end
    end
  end

  def process?(location:, request_type:)
    location&.strip.present? || request_type&.strip.present?
  end

  def build_data_requests(new_data_requests)
    return [] unless @case.respond_to? :data_requests

    new_data_requests.values.map do |data_request|
      next unless process?(
        **data_request.to_h.symbolize_keys.slice(:location, :request_type)
      )

      @case.data_requests.new(
        user: @user,
        location: data_request[:location],
        request_type: data_request[:request_type],
        date_requested: Date.current,
      )
    end.compact
  end
end

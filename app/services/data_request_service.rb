class DataRequestService
  attr_reader :result, :case

  def initialize(kase:, user:, data_requests:)
    @result = nil
    @user = user
    @case = kase
    @data_requests = data_requests
  end

  def call
    ActiveRecord::Base.transaction do
      begin
        @result = :unprocessed
        return if build_data_requests.empty?

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

  def process?(location:, data:)
    location&.strip.present? || data&.strip.present?
  end

  def build_data_requests
    @data_requests.values.map do |data_request|
      next unless process?(
        **data_request.to_h.symbolize_keys.slice(:location, :data)
      )

      @case.data_requests.new(
        user: @user,
        location: data_request[:location],
        data: data_request[:data]
      )
    end.compact
  end
end

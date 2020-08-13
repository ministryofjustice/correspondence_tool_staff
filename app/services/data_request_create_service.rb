class DataRequestCreateService
  attr_reader :result, :case, :data_request

  def initialize(kase:, user:, data_request:)
    @result = nil
    @user = user
    @case = kase
    @data_request = build_data_request(data_request)
  end

  def call
    ActiveRecord::Base.transaction do
      begin
        @result = :unprocessed
        return if @data_request.blank?

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

  private

  def build_data_request(data_request)
    return nil unless @case.respond_to? :data_requests
    @case.data_requests.new(
      user: @user,
      location: data_request[:location],
      request_type: data_request[:request_type],
      date_requested: Date.current,
    )
  end
end

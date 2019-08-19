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
        @data_requests.values.each do |data_request|
          @case.data_requests.new(
            user: @user,
            location: data_request[:location],
            data: data_request[:data]
          )
        end

        @case.save!
        @case.state_machine.mark_as_waiting_for_data!(
          acting_user: @user,
          acting_team: BusinessUnit.dacu_branston,
        )
        @result = :ok
     rescue ActiveRecord::RecordInvalid, ActiveRecord::AssociationTypeMismatch
       @result = :error
      end
    end
  end
end

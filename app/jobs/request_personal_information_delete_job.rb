class RequestPersonalInformationDeleteJob < ApplicationJob
  queue_as :rpi

  def perform
    SentryContextProvider.set_context
    PersonalInformationRequest.ready_to_delete.find_each(&:soft_delete)
  end
end

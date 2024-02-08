class RequestPersonalInformationJob < ApplicationJob
  queue_as :rpi

  def process(data)
    rpi = RequestPersonalInformationService.new(data)
    rpi.build
  end
end

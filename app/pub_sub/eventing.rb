module Eventing
  def broadcast(event)
    Rails.configuration.event_store.publish(event)
  end
end

require "rails_event_store"
require "aggregate_root"
require "arkency/command_bus"

require_relative "../../app/pub_sub/events/subscribers/email_subscriber"
require_relative "../../app/pub_sub/events/subscribers/rpi_subscriber"
require_relative "../../app/pub_sub/events/email_sent"
require_relative "../../app/pub_sub/events/rpi_received"
require_relative "../../app/pub_sub/events/rpi_processed"
require_relative "../../app/pub_sub/events/rpi_unprocessed"

Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::JSONClient.new
  Rails.configuration.command_bus = Arkency::CommandBus.new

  AggregateRoot.configure do |config|
    config.default_event_store = Rails.configuration.event_store
  end

  Rails.configuration.event_store.tap do |store|
    store.subscribe(Events::Subscribers::EmailSubscriber.new, to: [Events::EmailSent])
    store.subscribe(Events::Subscribers::RpiSubscriber.new, to: [Events::RpiReceived, Events::RpiProcessed, Events::RpiUnprocessed])

    store.subscribe_to_all_events(RailsEventStore::LinkByEventType.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCorrelationId.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCausationId.new)
  end
end

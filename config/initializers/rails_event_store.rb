require "rails_event_store"
require "aggregate_root"
require "arkency/command_bus"

require_relative "../../app/pub_sub/events/subscribers/email_subscriber"
require_relative "../../app/pub_sub/events/subscribers/rpi_subscriber"
require_relative "../../app/pub_sub/events/email_sent"
require_relative "../../app/pub_sub/events/rpi_processed"
require_relative "../../app/pub_sub/events/rpi_unprocessed"

Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::JSONClient.new
  Rails.configuration.command_bus = Arkency::CommandBus.new

  AggregateRoot.configure do |config|
    config.default_event_store = Rails.configuration.event_store
  end

  # Subscribe event handlers below
  Rails.configuration.event_store.tap do |store|
    # store.subscribe(InvoiceReadModel.new, to: [InvoicePrinted])
    # store.subscribe(lambda { |event| SendOrderConfirmation.new.call(event) }, to: [OrderSubmitted])
    # store.subscribe_to_all_events(lambda { |event| Rails.logger.info(event.event_type) })

    store.subscribe(Events::Subscribers::EmailSubscriber.new, to: [Events::EmailSent])
    store.subscribe(Events::Subscribers::RpiSubscriber.new, to: [Events::RpiProcessed, Events::RpiUnprocessed])

    store.subscribe_to_all_events(RailsEventStore::LinkByEventType.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCorrelationId.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCausationId.new)
  end

  # Register command handlers below
  # Rails.configuration.command_bus.tap do |bus|
  #   bus.register(PrintInvoice, Invoicing::OnPrint.new)
  #   bus.register(SubmitOrder, ->(cmd) { Ordering::OnSubmitOrder.new.call(cmd) })
  # end
end

module Events
  class SystemEvent < RailsEventStore::Event
    def self.build(data = {})
      new(data: (data || {}).compact)
    end
  end
end

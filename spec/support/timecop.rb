def freeze_time(&block)
  Timecop.freeze(Time.zone.local(2022, 10, 5), &block)
end

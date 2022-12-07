def freeze_time(&block)
  Timecop.freeze(Time.new(2022, 10, 1)) do
    yield
  end
end

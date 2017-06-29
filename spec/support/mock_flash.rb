
class MockFlash
  def initialize(values)
    @values = values
  end

  def now
    @values
  end

  def keep(key)
    # no_op
  end

  def [](key)
    @values[key]
  end

  def []=(key, value)
    @values[key] = value
  end
end

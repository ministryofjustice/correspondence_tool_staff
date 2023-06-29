class MockFlash
  attr_reader :kept

  def initialize(values)
    @values = values
    @kept = []
  end

  def now
    @values
  end

  def keep(key)
    @kept << key
  end

  def [](key)
    @values[key]
  end

  def []=(key, value)
    @values[key] = value
  end
end

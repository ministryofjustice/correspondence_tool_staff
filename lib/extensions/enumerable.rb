module Enumerable
  class NotSingular < StandardError
  end

  def singular
    raise NotSingular, "length #{length} is not 1" if length != 1

    first
  end

  def singular_or_nil
    raise NotSingular, "length #{length} is greater than 1" if length > 1

    first
  end
end

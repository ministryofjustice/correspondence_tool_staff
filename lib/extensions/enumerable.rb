module Enumerable
  class NotSingular < StandardError
  end

  def singular
    raise NotSingular.new("length #{length} is not 1") if length != 1
    self.first
  end
end

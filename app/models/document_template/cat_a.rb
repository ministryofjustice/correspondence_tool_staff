module DocumentTemplate
  class CatA < DocumentTemplate::Base
    def context
      super.merge(deadline: deadline(5))
    end
  end
end

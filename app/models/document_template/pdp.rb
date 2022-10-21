module DocumentTemplate
  class PDP < DocumentTemplate::Base
    def context
      super.merge(
        {
          aliases: kase.subject_aliases,
        }
      )
    end
  end
end

module DocumentTemplate
  class CrossBorder < DocumentTemplate::Base
    def context
      super.merge(
        {
          aliases: kase.subject_aliases,
          deadline: deadline(5),
        }
      )
    end
  end
end

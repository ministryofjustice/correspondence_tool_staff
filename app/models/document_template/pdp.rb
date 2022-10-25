module DocumentTemplate
  class Pdp < DocumentTemplate::Base
    def context
      super.merge(aliases: kase.subject_aliases)
    end
  end
end

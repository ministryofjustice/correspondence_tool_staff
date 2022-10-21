module DocumentTemplate
  class Prison < DocumentTemplate::Base
    def context
      super.merge(
        addressee_location: data_request.location,
        aliases: kase.subject_aliases,
        deadline: deadline(5),
      )
    end
  end
end

module CaseFilter
  class CaseFilterBase
    include FilterParamParsers
    attr_reader :available_choices

    def self.identify
      raise '#call should be defined in sub-class of CaseFilterBase'
    end

    def self.filter_attributes
      []
    end

    def self.set_params(params)
      []
    end

    def self.date_fields
      []
    end

    def self.filter_fields(filter_fields)
      {}
    end

    def self.process_params!(params)
      filter_attributes.each do | filter_attribute |
        process_array_param(params, filter_attribute)
      end
    end

    def self.template_name
      raise '#call should be defined in sub-class of CaseFilterBase'
    end

    def initialize(query, user, records)
      @query = query
      @records = records
      @user = user

      @available_choices = get_available_choices
    end

    def get_available_choices
      nil
    end

    def is_available?
      true
    end

    def applied?
      self.class.filter_attributes.any? { | filter_attribute| @query.send(filter_attribute).present? }
    end

    def call
      raise '#call should be defined in sub-class of CaseFilterBase'
    end

    def crumbs
      raise '#crumbs should be defined in sub-class of CaseFilterBase'
    end

  end
end

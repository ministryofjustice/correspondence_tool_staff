module CaseFilter
  class CaseFilterBase
    include FilterParamParsers
    attr_reader :available_choices

    class << self
      def identifier
        raise "#identifier should be defined in sub-class of CaseFilterBase"
      end

      def filter_attributes
        []
      end

      def set_params(_)
        raise "#set_params should be defined in sub-class of CaseFilterBase"
      end

      def date_fields
        []
      end

      def filter_fields(_)
        raise "#filter_fields should be defined in sub-class of CaseFilterBase"
      end

      def process_params!(params)
        filter_attributes.each do |filter_attribute|
          process_array_param(params, filter_attribute)
        end
      end

      def template_name
        raise "#template_name should be defined in sub-class of CaseFilterBase"
      end
    end

    def initialize(query, user, records)
      @query = query
      @records = records
      @user = user

      @available_choices = nil
    end

    def is_permitted_for_user?
      true
    end

    def applied?
      self.class.filter_attributes.any? { |filter_attribute| @query.send(filter_attribute).present? }
    end

    def call
      raise "#call should be defined in sub-class of CaseFilterBase"
    end

    def crumbs
      raise "#crumbs should be defined in sub-class of CaseFilterBase"
    end
  end
end

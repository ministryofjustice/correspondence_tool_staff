class CaseLinkDecorator < Draper::Decorator
  decorates Case::Base
  delegate_all

  attr_accessor :linked_case_number
end

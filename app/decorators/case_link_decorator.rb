class CaseLinkDecorator < Draper::Decorator
  decorates Case
  delegate_all

  attr_accessor :linked_case_number
end

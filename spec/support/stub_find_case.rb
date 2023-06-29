# Utility method to help us setup expectations on cases.
#
# Without this approach, it's messy to set expectations on @case in the
# controller as stubbing out the return value from Case.find is frought
# with yuckiness ... e.g. @case.transitions.order...
def stub_find_case(id, &block)
  allow(Case::Base).to receive(:find).with(id.to_s)
                   .and_wrap_original do |original_method, *args|
    original_method.call(*args).tap(&block)
  end
end

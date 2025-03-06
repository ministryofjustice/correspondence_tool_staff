# Utility method to help us setup expectations on cases when the SetupCase.set_case method has been used
def stub_find_case(kase)
  allow(Case::Base).to receive_message_chain(:includes, :find).with(kase.id.to_s).and_return(kase) # rubocop:disable RSpec/MessageChain
end

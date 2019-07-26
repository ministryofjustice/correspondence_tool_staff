require 'rails_helper'

RSpec.describe Cases::CaseTransitionsController, type: :controller do
  it_behaves_like 'edit offender sar spec', :offender_sar_case, :mark_as_waiting_for_data
  it_behaves_like 'edit offender sar spec', :waiting_for_data_offender_sar, :mark_as_ready_for_vetting
  it_behaves_like 'edit offender sar spec', :ready_for_vetting_offender_sar, :mark_as_vetting_in_progress
  it_behaves_like 'edit offender sar spec', :vetting_in_progress_offender_sar, :mark_as_ready_to_copy
  it_behaves_like 'edit offender sar spec', :ready_to_copy_offender_sar, :mark_as_ready_to_dispatch
  # it_behaves_like 'edit offender sar spec', :ready_to_dispatch_offender_sar, :mark_as_closed
end

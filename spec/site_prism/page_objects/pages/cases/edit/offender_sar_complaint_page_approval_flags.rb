module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARComplaintPageApprovalFlags < PageObjects::Pages::Base
          set_url "/cases/offender_sar_complaints/{id}/edit/approval_flags"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :submit_button, ".button"

          def choose_approval_flags(is_ico, approval_flags)
            complete_approval_flags(is_ico).each do |flag|
              if approval_flags.include?(flag.id)
                make_check_box_choice("offender_sar_complaint_approval_flag_ids_#{flag.id}")
              else
                remove_check_box_choice("offender_sar_complaint_approval_flag_ids_#{flag.id}")
              end
            end
          end

          def unchoose_approval_flags(is_ico, approval_flags)
            complete_approval_flags(is_ico).each do |flag|
              if approval_flags.include?(flag.id)
                remove_check_box_choice("offender_sar_complaint_approval_flag_ids_#{flag.id}")
              else
                make_check_box_choice("offender_sar_complaint_approval_flag_ids_#{flag.id}")
              end
            end
          end

        private

          def complete_approval_flags(is_ico)
            if is_ico
              CaseClosure::ApprovalFlag::ICOOffenderComplaint.active
            else
              CaseClosure::ApprovalFlag::LitigationOffenderComplaint.active
            end
          end
        end
      end
    end
  end
end

module PageObjects
  module Sections
    module Cases
      class ExemptionFilterPanelSection < SitePrism::Section
        section :most_used, "#common_exemption_ids_group" do
          # The following checkboxes are invisible because ... govuk form
          # elements. Check for visibility on the panel section, not the
          # checkboxes

          def checkbox_for(exemption)
            unless exemption.is_a? CaseClosure::Exemption
              exemption = CaseClosure::Exemption.__send__ exemption.to_s
            end
            find "#search_query_common_exemption_ids_#{exemption.id}",
                 visible: false
          end

          element :s21_checkbox, :xpath, '//div[@id="common_exemption_ids_group"]//label[contains(.,"s21")]'
          element :s22_checkbox, :xpath, '//div[@id="common_exemption_ids_group"]//label[contains(.,"s22")]'
          element :s32_checkbox, :xpath, '//div[@id="common_exemption_ids_group"]//label[contains(.,"s32")]'
          element :s40_checkbox, :xpath, '//div[@id="common_exemption_ids_group"]//label[contains(.,"s40")]'
        end

        section :exemption_all, "#exemption_ids_group" do
          # The following checkboxes are invisible because ... govuk form
          # elements. Check for visibility on the panel section, not the
          # checkboxes

          def checkbox_for(exemption)
            unless exemption.is_a? CaseClosure::Exemption
              exemption = CaseClosure::Exemption.__send__ exemption.to_s
            end
            find "#search_query_exemption_ids_#{exemption.id}",
                 visible: false
          end

          element :ncnd_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"`NCND`")]'
          element :s12_1_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s12(1)")]'
          element :s21_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s21")]'
          element :s22_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"(s22)")]'
          element :s22A_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s22A")]'
          element :s23_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s23")]'
          element :s24_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s24")]'
          element :s26_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s26")]'
          element :s27_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s27")]'
          element :s28_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s28")]'
          element :s29_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s29")]'
          element :s30_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s30")]'
          element :s31_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s31")]'
          element :s32_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s32")]'
          element :s33_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s33")]'
          element :s34_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s34")]'
          element :s35_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s35")]'
          element :s36_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s36")]'
          element :s37_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s37")]'
          element :s38_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s38")]'
          element :s39_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s39")]'
          element :s40_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s40")]'
          element :s41_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s41")]'
          element :s42_checkbox, :xpath, '//div[@id="exemption_ids_group"]//label[contains(.,"s42")]'
        end
      end
    end
  end
end

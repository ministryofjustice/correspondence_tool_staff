moj.Modules.RequesterDetails = {
    $is_solicitor: $("#offender_sar_is_solicitor_solicitor"),
    $is_other : $("#offender_sar_is_solicitor_other"),

    $is_third_party: $("#offender_sar_third_party_true"),
    $is_not_third_party: $("#offender_sar_third_party_false"),



    init: function() {
        var self = this;

        var revealing_panel_address_page_check = $(".js-in-revealing-panel-address-lookup").length;
        var relationship_is_not_with_solicitor = $("#offender_sar_third_party_relationship").val() !== "Solicitor";

        if (revealing_panel_address_page_check) {
            var is_fresh_page = !(self.$is_third_party[0].checked || self.$is_not_third_party[0].checked);

            if (is_fresh_page) {
              self.set_and_hide_relationship();
            } else {
                if (relationship_is_not_with_solicitor) {
                   $("#offender_sar_is_solicitor_other").prop('checked', 'checked');
                } else {
                  self.set_and_hide_relationship();
                }
            }


            self.$is_third_party.on('change', function(){
                if ($("#offender_sar_is_solicitor_other")[0].checked) {
                    var input = $('#offender_sar_third_party_relationship');
                    var label = $('#third_party_true_panel > div:nth-child(2) > label');
                    label.show();
                    input.show();
                } 
            });

            self.$is_other.on('change', function(){
                self.show_relationship_input();
                $('#open-button').hide(); 
            });

            self.$is_solicitor.on('change', function(){
                self.set_and_hide_relationship();
                $('#open-button').show(); 
            });
        }
    },

    set_and_hide_relationship: function() {
        var is_solicitor = $("#offender_sar_is_solicitor_solicitor");
        var input = $('#offender_sar_third_party_relationship');
        var label = $('#third_party_true_panel > div:nth-child(2) > label');
        label.hide();
        input.hide();
        input.val('Solicitor');
        is_solicitor.prop('checked', 'checked');
    },

    show_relationship_input: function() {
        var input = $('#offender_sar_third_party_relationship');
        var label = $('#third_party_true_panel > div:nth-child(2) > label');
        label.show();
        input.show();
        input.val('');
    }
};

moj.Modules.RequesterDetails = {
    $is_solicitor: $("#offender_sar_is_solicitor_solicitor"),
    $is_other : $("#offender_sar_is_solicitor_other"),
    $is_third_party: $("#offender_sar_third_party_true"),


    init: function() {
        var self = this;
        self.$is_third_party.on('change', function(){
            self.set_and_hide_relationship();
        });
        self.$is_other.on('change', function(){
            self.show_relationship_input();
            var address_button = $('#open-button');
            address_button.hide(); 
        });
        self.$is_solicitor.on('change', function(){
            self.set_and_hide_relationship();
            var address_button = $('#open-button');
            address_button.show(); 
        });

        $( document ).ready(function() {
            console.log("hi");
            self.on_load();
        });
    },

    set_and_hide_relationship: function() {
        var is_solicitor = $("#offender_sar_is_solicitor_solicitor");
        var input = $('#offender_sar_third_party_relationship');
        var label = $('#third_party_true_panel > div:nth-child(2) > label');
        label.hide();
        input.hide();
        input.val('Solicitor');
        is_solicitor.attr('checked', 'checked');
    },

    show_relationship_input: function() {
        var input = $('#offender_sar_third_party_relationship');
        var label = $('#third_party_true_panel > div:nth-child(2) > label');
        label.show();
        input.show();
        input.val('');
    },

    on_load: function() {
        var is_solicitor = $("#offender_sar_is_solicitor_solicitor");
        var input = $('#offender_sar_third_party_relationship');
        var label = $('#third_party_true_panel > div:nth-child(2) > label');
        var address_button = $('#open-button');
        if(input.val() === 'Solicitor') {
            label.hide();
            input.hide();
            input.val('Solicitor');
            is_solicitor.attr('checked', 'checked');
        } else {
          address_button.hide();
        }
    }

};

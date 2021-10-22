moj.Modules.DefaultSolicitorAddressSearch = {
    $solicitor_radio_button: $("#offender_sar_is_solicitor_solicitor"),
    $other_radio_button: $("#offender_sar_is_solicitor_other"),

    $radio_option_with_revealing_panel: $(".option_with_revealing_panel input[type=radio]"),
    $radio_option_without_revealing_panel: $(".option_without_revealing_panel input[type=radio]"), 

    $relationship_input_label : $('#offender_sar_third_party_relationship').parent().find('label'),
    $relationship_text_input : $('#offender_sar_third_party_relationship'),


    init: function() {
        var self = this;

        if (self.is_page_with_revealing_address_panel()) {

            // logic if user is creating a new record
            if (self.is_fresh_page()) {
                self.set_relationship_to_solicitor();
            } else {
                
                // logic if user is loading existing record
                if (self.relationship_is_not_with_solicitor()) {
                    self.change_relationship_to_other();
                } else {
                    self.set_relationship_to_solicitor();
                }
            }


            // event bindings to set things after user interactions
            
            // For "Other" radio button changes
            self.$other_radio_button.on('change', function(){
                self.show_relationship_input();
            });

            // For "Solicitor" radio button changes
            self.$solicitor_radio_button.on('change', function(){
                self.set_relationship_to_solicitor();
            });
        }
    },

    change_relationship_to_other : function(){
        this.$other_radio_button.prop('checked', 'checked');
        this.hide_address_button();
    },

    is_fresh_page : function(){
        var revealing_panel_option_selected = this.$radio_option_with_revealing_panel[0].checked;
        var non_revealing_panel_option_selected = this.$radio_option_without_revealing_panel[0].checked;
        return !(revealing_panel_option_selected || non_revealing_panel_option_selected);
    },

    relationship_is_not_with_solicitor : function(){
        return $("#offender_sar_third_party_relationship").val() !== "Solicitor";
    },

    is_page_with_revealing_address_panel : function(){
        return $(".js-in-revealing-panel-address-lookup").length;
    },

    set_relationship_to_solicitor: function() {
        this.$relationship_input_label.hide();
        this.$relationship_text_input.hide();
        this.$relationship_text_input.val('Solicitor');
        this.$solicitor_radio_button.prop('checked', 'checked');
        this.show_address_button();
    },

    show_relationship_input: function() {
        this.$relationship_input_label.show();
        this.$relationship_text_input.show();
        this.$relationship_text_input.val('');
        this.hide_address_button();
    },

    hide_address_button: function(){
        $('#open-button').hide(); 
    },

    show_address_button: function(){
        $('#open-button').show(); 
    }
};

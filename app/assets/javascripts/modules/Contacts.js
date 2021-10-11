moj.Modules.Contacts = {
    $button : $("#open-button"),
    $remote_content : $("#remote-content"),
    $dialog : $("#dialog-content").dialog({
        autoOpen: false,
        height: 400,
        width: 600,
        modal: true,
        title: 'Find a location'
    }),
    $search_filters: $('#open-button').data('searchFilters'),

    init: function() {
        this.attach_button_event_to_open_dialog();
    },

    attach_button_event_to_open_dialog: function() {
        var self = this;

        self.$button.on( "click", function(e) {
            e.preventDefault();

            self.load_modal_form();

            $('#dialog-content').parent().attr('aria-modal','true');
            $('#dialog-content').parent().removeAttr('aria-describedby','');
        });
    },

    load_modal_form : function(){
        var self = this;
        self.$remote_content.load("/contacts_search?search_filters=" + self.$search_filters, function() {
            self.$dialog.dialog( "open" );

            setTimeout(function() { 
                $('#popup-search-button').focus(); 
            }, 1); // fix voiceover focus issue

            setTimeout(function() { 
                $('#popup-search').focus(); 
            }, 2); // fix voiceover focus issue
        });
    },

    set_search_filters : function() {
        var $form = $('#contacts_search_form');
        var $form_action = $form.attr('action');
        var form_action_with_params = $form_action + '?search_filters=' + this.$search_filters;
        $form.attr('action', form_action_with_params);
    },

    attach_address_selection_button_events : function() {
        $('.use-address-button').on('click', function(e){
            var name = $($(this).parent().find('.contact-name')[0]).text();
            var address = $($(this).parent().find('.contact-address')[0]).text();

            var formatted_address = name + "\n" + address;

            $('#dialog-content').dialog( "close" );

            $('#offender_sar_subject_address').val(formatted_address);
        });
    },

    search_results_loaded : function() { // To refocus on Search for NVDA after popup re-renders
        $('#popup-search-button').focus(); // fix NVDA focus issue after search
    }

};

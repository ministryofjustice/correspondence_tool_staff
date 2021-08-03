moj.Modules.Contacts = {
    $button : $("#open-button"),
    $remote_content : $("#remote-content"),
    $dialog : $("#dialog-content").dialog({
        autoOpen: false,
        height: 400,
        width: 350,
        modal: true,
        title: 'Find address',
        close: function(event, ui) { console.log(event); }
    }),

    init: function() {
        var self = this;

        self.attach_finder_button_event();


    },

    attach_finder_button_event: function() {
        var self = this;

        self.$button.on( "click", function(e) {
            e.preventDefault();

            self.$remote_content.load("/contacts_search", function() {
                self.$dialog.dialog( "open" );

                setTimeout(function() { 
                    $('#popup-search-button').focus(); 
                },1); // fix voiceover focus issue

                setTimeout(function() { 
                    $('#popup-search').focus(); 
                },2); // fix voiceover focus issue
                console.log('initial load');
            });
            $('#dialog-content').parent().attr('aria-modal','true');
            $('#dialog-content').parent().removeAttr('aria-describedby','');
        });
    },

    fill_in_address : function (address){
        console.log('fill_in_address');
        $dialog.dialog('close');
        $('#offender_sar_subject_address').val(address);
    },

    search_results_loaded : function () { // To refocus on Search for NVDA after popup re-renders
        console.log('results loaded');
        $('#popup-search-button').focus(); // fix NVDA focus issue after search
    }   

};

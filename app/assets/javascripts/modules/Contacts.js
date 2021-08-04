moj.Modules.CaseCreation = {
    $dialog : $( "#dialog-form" ).dialog({
        autoOpen: false,
        height: 500,
        width: 600,
        modal: true,
    }),

    $search_data : null,

    $list_elem_template : $('#address-details > li'),
    $address_results_list : $('#address-details'),

    init: function() {
        var self = this;
        self.addOpenDialogEvent();
        self.addSearchButtonEvent();
    },

    addOpenDialogEvent : function() {
        var self = this;
        $( "#find-address" ).on( "click", function(e) { 
            e.preventDefault();
            self.$dialog.dialog( "open" );
        });
    },

    addSearchButtonEvent :function() {
        var self = this;
        $( "#search-button" ).button().on( "click", function(e) {
            e.preventDefault();
            var search_term = $("#contacts-search-field").val();
            var search_url = "/contacts_search?contacts_search_value=" + search_term;

            $.getJSON(search_url)
                .done(function(data){
                    self.$address_results_list.empty();
                    self.$search_data = data; 
                    self.appendAddressDataToModal(data);
                    self.addSelectionButtonEvents();
                })
                .fail(function( jqxhr, textStatus, error ) {
                    var err = textStatus + ", " + error;
                    console.log( "Request Failed: " + err );
                });

            self.$dialog.dialog( "open" );
        });
    },

    appendAddressDataToModal : function(contacts) {
        var self = this;
        $.each(contacts, function(id, contact) {
            var address_list_item = self.prepareResultsAddressListElement(
                self.$list_elem_template,
                id,
                contact
            );
            self.$address_results_list.append(address_list_item);
        });
    },

    prepareResultsAddressListElement : function(list_elem_template, id, contact) {
        var list_item = list_elem_template.clone();
        var name = $(list_item.find('.contact-name')[0]);
        var address = $(list_item.find('.contact-address')[0]);
        var button = $(list_item.find('.use-address-button')[0]);
        var address_id = $(list_item.find('.address-id')[0]);
        name.text(contact.name);
        address.text(contact.address);
        button.text("Use " + contact.name);
        button.css('display', 'inline');
        list_item.css('display', 'block');
        address_id.val(id.toString());
        return list_item;
    },

    addSelectionButtonEvents : function() {
        var self = this;
        $('.use-address-button').on('click', function(){
            var address_id = $($(this).parent().find('.address-id')[0]).val();
            var address = self.$search_data[address_id];
            var formatted_address = address.name + "\n" + address.address;
            self.$dialog.dialog( "close" );
            $('#address-field').text("");
            $('#address-field').text(formatted_address); 
        });
    }
};

moj.Modules.AssignedToFilter = {
    businessUnitsArr: '',

    init: function () {

        if ($('#search_query_business_unit_name_filter').length === 0 ){
            return;
        }
        var module = this;

        module.businessUnitsArr = [[16,"Legal Aid Agency (LAA)"],
            [17,"MoJ Human Resources (MoJ HR)"],
            [18,"North East Regional Support Unit (NE RSU)"],
            [19,"HMCTS Property Directorate"],
            [20,"Upper Tribunal Asylum Chamber"],
            [21,"Upper Tribunal Lands (UT Lands)"],
            [22,"Upper Tibunal - Tax \ Chancery Chamber"],
            [23,"Communications and Information"]];


        $('#search_query_business_unit_name_filter').on('keyup', function(){
            if(this.value !== '') {
                $('.js-all-business-units').show();
                module.getMatchingBusinessUnits(this.value);
            } else {
                $('.js-all-business-units').hide();
            }
        }).trigger('keyup')
    },


    getMatchingBusinessUnits: function (searchFor){
        $('.js-all-business-units').find('.multiple-choice')
            .each(function( index, element ) {
                var $elem = $(this);
                var labelText = $elem.text().replace(/[^a-z0-9+]+/gi, '');
                var cleanedTerm = searchFor.replace(/[^a-z0-9+]+/gi, '');
                var check = new RegExp(cleanedTerm, 'gi')

                if (check.test(labelText)){
                    $elem.show();
                }else{
                    $elem.hide();
                    $elem.find(':checkbox').prop('checked', false);
                }
            })
    }

}

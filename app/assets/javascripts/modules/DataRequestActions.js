moj.Modules.DataRequestActions = {

  init: function () {
    var self = this;

    $('#data_request_completed').on('click', function(){
      var $elem = $(this);
      var $dd_field = $('#data_request_cached_date_received_dd');
      var $mm_field = $('#data_request_cached_date_received_mm');
      var $yyyy_field = $('#data_request_cached_date_received_yyyy');

      if ($elem.is(':checked') && $dd_field.val() == '' && $mm_field.val() == '' && $yyyy_field.val() == '') {
        var d = new Date();

        var month = d.getMonth()+1;
        var day = d.getDate();
        var year = d.getFullYear()

        $dd_field.val(day);
        $mm_field.val(month);
        $yyyy_field.val(year);
      }
    });
  },
};

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

    $('#new_data_request').submit(function() {
      self.clearNoteField();
    });

    $('#edit_data_request').submit(function() {
      self.clearNoteField();
    });

  },

  clearNoteField: function() {
    if (!$('#data_request_request_type_bwcf').is(':checked')) {
      $('#request_type_note_for_bwcf_panel').empty();
    }
    if (!$('#data_request_request_type_cctv').is(':checked')) {
      $('#request_type_note_for_cctv_panel').empty();
    }
    if (!$('#data_request_request_type_other').is(':checked')) {
      $('#request_type_other_panel').empty();
    }
    if (!$('#data_request_request_type_nomis_other').is(':checked')) {
      $('#request_type_nomis_other_panel').empty();
    }
  }

};

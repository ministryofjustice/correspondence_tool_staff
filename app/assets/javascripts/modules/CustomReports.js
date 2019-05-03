moj.Modules.CustomReports = {
  $correspondenceTypes  : $('#js-correspondence-types'),
  $optionPanels     : $('#js-report-types .js-report-type-options'),

  init: function () {
    var self = this;

    self.showHideReportsTypes();

    //Bind events
    self.$correspondenceTypes.on('change', ':radio', function(){
      self.showHideReportsTypes();
    });

    // Pre-select case type
    var select = $.urlParam('select');
    if (select) {
      $('input[value="' + select + '"]', this.$correspondenceTypes).each(function(){
        this.click();
      });
    }
  },

  showHideReportsTypes: function (){
    if (this.$correspondenceTypes.length > 0){
      this.$optionPanels.each(function(){
        $(this).hide();

        $('input[type="hidden"]', this).each(function() {
          $(this).prop('disabled', true);
        });
      });

      var selected = $('.js-correspondence-type input:checked', this.$correspondenceTypes);

      if (selected.length) {
        var panel = this.$optionPanels.filter('[data-report-type="' + selected[0].value + '"]');

        if (panel.length) {
          panel.show();

          // Some Report Types are the default report type for a given Case
          // Type (e.g. Closed Cases Report) and therefore automatically
          // set for form submission
          $('input[type="hidden"]', panel).each(function() {
            $(this).prop('disabled', false);
          });
        }
      }
    }
  },
};

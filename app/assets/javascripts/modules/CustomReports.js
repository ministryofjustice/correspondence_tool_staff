moj.Modules.CustomReports = {
  $correspondenceTypes  : $('.js-correspondence-types'),
  $optionPanels     : $('.js-report-type-options'),

  init: function () {
    var self = this;

    self.showHideReportsTypes();

    //Bind events
    self.$correspondenceTypes.on('change', ':radio', function(){
      self.showHideReportsTypes();
    });

    self.selectCorrespondenceType();
  },

  // Pre-select case type if supplied
  selectCorrespondenceType: function() {
    var select = $.urlParam('select');

    if (select) {
      $('input[value="' + select + '"]', this.$correspondenceTypes).each(function(){
        this.click();
      });
    }
  },

  showHideReportsTypes: function () {
    if (this.$correspondenceTypes.length > 0){
      this.$optionPanels.each(function(){
        $(this).hide();

        $('input[type="hidden"]', this).each(function() {
          $(this).prop('disabled', true);
        });

        // Radios have the same name, so if a hidden radio is checked
        // it will break the keyboard tabbing - since the keyboard
        // tabbing defaults to the selected radio
        $('input[type="radio"]', this).each(function() {
          $(this).prop('checked', false);
        });
      });

      var selected = $('input:checked', this.$correspondenceTypes);

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

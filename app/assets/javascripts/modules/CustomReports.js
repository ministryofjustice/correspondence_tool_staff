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
  },

  showHideReportsTypes: function (){
    if (this.$correspondenceTypes.length > 0){
      this.$optionPanels.each(function(){
        $(this).hide();
      });

      var selected = $('.js-correspondence-type input:checked', this.$correspondenceTypes);

      if (selected.length) {
        var panel = this.$optionPanels.filter('[data-report-type="' + selected[0].value + '"]');

        if (panel.length) {
          panel.show();
        }
      }
    }
  }
};

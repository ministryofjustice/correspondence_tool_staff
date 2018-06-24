moj.Modules.CustomReports = {
  $correspondenceTypes  : $('#js-correspondence-types'),
  $FOIOption        : $('#report_correspondence_type_foi'),
  $SAROption        : $('#report_correspondence_type_sar'),
  $FOIReports       : $('#js-report-types-foi'),
  $SARReports       : $('#js-report-types-sar'),

  init: function () {
    var self = this;

    self.showHideReportsTypes();

    //Bind events
    self.$correspondenceTypes.on('change', ':radio', function(){

      self.showHideReportsTypes();

    });
  },

  showHideReportsTypes: function (){
    //If we have multiple types
    if (this.$correspondenceTypes.length > 0){
      if (this.$SAROption.is(':checked')){

        this.$FOIReports.hide();
        this.$SARReports.show();

      } else if(this.$FOIOption.is(':checked') ){

        this.$FOIReports.show();
        this.$SARReports.hide();

      } else {

        this.$FOIReports.hide();
        this.$SARReports.hide();

      }
    }
  }
};

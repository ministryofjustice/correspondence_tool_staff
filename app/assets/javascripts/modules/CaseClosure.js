moj.Modules.CaseClosure = {
  $refusal          : $('#refusal'),

  $refusedOutcomes  : $('#case_outcome_name_refused_in_part,' +
                       ' #case_outcome_name_refused_fully'),

  $exemptionApplied : $('#case_refusal_reason_name_exemption_applied'),

  $refusalExemptions: $('#refusal_exemptions'),

  init: function () {
    var self = this;

    self.showHideRefusalReasons();

    self.showHideExemptions();

    //Bind events
    $('#outcome').on('change', ':radio', function(){

      self.showHideRefusalReasons();

    });

    $('#refusal_reasons').on('change', ':radio', function(){

      self.showHideExemptions();

    });

  },

  showHideRefusalReasons: function (){
    if (this.$refusedOutcomes.is(':checked')){

      this.$refusal.show();

      moj.Modules.CaseClosure.showHideExemptions();

    } else {

      this.$refusal.hide();

    }
  },

  showHideExemptions: function (){
    if (this.$exemptionApplied.is(':checked')){

      this.$refusalExemptions.show();

    }else{

      this.$refusalExemptions.hide();

    }
  }
};

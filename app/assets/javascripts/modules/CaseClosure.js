moj.Modules.CaseClosure = {

  $infoHeldGroup : $('.js-info-held-status'),

  $infoIsHeld : $('#foi_info_held_status_abbreviation_held, #foi_info_held_status_abbreviation_part_held'),

  $infoOther : $('#foi_info_held_status_abbreviation_not_confirmed'),

  $outcomeGroup : $('.js-outcome-group'),

  $outcomeRefusedPartly : $('#foi_outcome_abbreviation_part'),

  $outcomeRefused : $('#foi_outcome_abbreviation_part, #foi_outcome_abbreviation_refused'),

  $otherReasons : $('.js-other-reasons'),

  $refusalNCND : $('#foi_refusal_reason_abbreviation_ncnd'),

  $refusalExemptions : $('.js-refusal-exemptions'),


  // SAR IR specific variables
  $sarIrOutcomeGroup : $('.appeal-outcome-group'),
  $sarIrOutcomeUpheldInPart : $('#sar_internal_review_sar_ir_outcome_upheld_in_part'),
  $sarIrOutcomeOverturned : $('#sar_internal_review_sar_ir_outcome_overturned'),
  $outcomeExplanationGroups : $('.responsible-for-outcome-group, .outcome-reasons-group'),

  $otherOverturned : $('.js-other-overturned'),
  $outcomeReasonOtherOption : $('#sar_internal_review_other'),

  init: function() {
    var self = this;

    self.showHideOtherGroup();

    self.showHideExemption();

    self.showHideOutcomeExplantionGroups();

    self.showHideOtherOverturned();

    self.$outcomeReasonOtherOption.on('click', function() {
      self.showHideOtherOverturned();
    });

    self.$sarIrOutcomeGroup.on('change', ':radio', function() {
      self.showHideOutcomeExplantionGroups();
    });

    //Bind events
    self.$infoHeldGroup.on('change', ':radio', function(){
      self.showHideOtherGroup();
    });

    self.$outcomeGroup.on('change', ':radio', function() {
      self.showHideExemption();
    });

    self.$otherReasons.on('change', ':radio', function() {
      self.showHideExemption();
    });
  },

  showHideOtherOverturned: function() {
      var other_is_checked = this.$outcomeReasonOtherOption.is(':checked');
      var other_option_details_has_value = $('#sar_internal_review_other_option_details').val() ? true : false;

      if (other_is_checked || other_option_details_has_value) {
        this.$otherOverturned.show();
      } else {
        this.$otherOverturned.hide();
      }
  },

  showHideOutcomeExplantionGroups: function() {
    var upheldInPart = this.$sarIrOutcomeUpheldInPart.is(':checked');
    var overturned = this.$sarIrOutcomeOverturned.is(':checked');

    if (upheldInPart || overturned) {
      this.$outcomeExplanationGroups.show();
    } else {
      this.$outcomeExplanationGroups.hide();
    }
  },

  showHideOtherGroup: function() {
    if(this.$infoIsHeld.is(':checked')) {
      this.$outcomeGroup.show();
      this.enableOptions(this.$outcomeGroup);
      this.$otherReasons.hide();
      this.disableOptions(this.$otherReasons);

      moj.Modules.CaseClosure.showHideExemption();
    } else if (this.$infoOther.is(':checked')) {
      this.$otherReasons.show();
      this.enableOptions(this.$otherReasons);
      this.$outcomeGroup.hide();
      this.disableOptions(this.$outcomeGroup);
      moj.Modules.CaseClosure.showHideExemption();
    } else {
      this.$outcomeGroup.hide();
      this.disableOptions(this.$outcomeGroup);
      this.$otherReasons.hide();
      this.disableOptions(this.$otherReasons);
      this.$refusalExemptions.hide();
      this.disableOptions(this.$refusalExemptions);
    }
  },

  showHideExemption: function() {
    if((this.$infoIsHeld.is(':checked') && this.$outcomeRefused.is(':checked')) ||
      (this.$infoOther.is(':checked') && this.$refusalNCND.is(':checked'))) {
      this.$refusalExemptions.show();
      this.enableOptions(this.$refusalExemptions);
    }else{
      this.$refusalExemptions.hide();
      this.disableOptions(this.$refusalExemptions);
    }

    moj.Modules.CaseClosure.showHideExemptionCost();
  },

  showHideExemptionCost: function() {
    var $refusalCostExemptionOption = this.$refusalExemptions
                                .find('input:checkbox[data-omit-for-part-refused="true"]')
                                .closest('.multiple-choice');
    var $outcomeRefusedPartlyOption = this.$outcomeRefusedPartly.closest('.multiple-choice');

    var $NCNDLabel = this.$refusalNCND.closest('label');

    var selectedRefusedPartly = $outcomeRefusedPartlyOption.is(':visible')
                                  && this.$outcomeRefusedPartly.is(':checked');

    var selectedNCND = $NCNDLabel.is(':visible') && this.$refusalNCND.is(':checked');

    if(selectedRefusedPartly || selectedNCND ) {
      $refusalCostExemptionOption.hide();
      this.disableOptions($refusalCostExemptionOption);
    } else {
      $refusalCostExemptionOption.show();
      this.enableOptions($refusalCostExemptionOption);
    }
  },

  enableOptions: function($el) {
    $el.find(':radio,:checkbox').prop('disabled', false);
  },

  disableOptions: function($el) {
    $el.find(':radio,:checkbox').prop('disabled', true);
  }

};

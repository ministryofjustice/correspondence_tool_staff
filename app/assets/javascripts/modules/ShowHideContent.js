moj.Modules.ShowHideContent = {
  el: 'label:has(":radio, :checkbox")',
  init: function() {
    var self = this;

    var showHideContent = new GOVUK.ShowHideContent();

    self.cacheEls();

    self.bindEvents();

    showHideContent.init();
  },

  cacheEls: function(){
    this.radioButtonLabels = $(this.el);
  },

  bindEvents: function() {
    this.radioButtonLabels.each(function (index, element) {
      var showHideTarget = element.getAttribute('for') + '_content';
      element.setAttribute('data-target', showHideTarget);
    });
  }

};

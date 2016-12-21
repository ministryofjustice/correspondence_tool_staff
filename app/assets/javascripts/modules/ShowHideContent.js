moj.Modules.ShowHideContent = {
  elementSelector: 'label:has(":radio, :checkbox")',
  init: function() {
    var self = this;

    var showHideContent = new GOVUK.ShowHideContent();

    self.cacheEls();

    self.bindEvents();

    showHideContent.init();
  },

  cacheEls: function(){
    this.govukLabels = $(this.elementSelector);
  },

  bindEvents: function() {
    this.govukLabels.each(function (index, element) {
      var showHideTarget = element.getAttribute('for') + '_content';
      element.setAttribute('data-target', showHideTarget);
    });
  }

};

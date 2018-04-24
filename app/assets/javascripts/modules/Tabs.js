// tabbed panels
'use strict';

//var Cookies = require('js-cookie');

moj.Modules.Tabs = {
  init: function () {
    this.bindEvents($('.ct-tab'));
  },

  bindEvents: function ($tabButtons) {
    if ($tabButtons.length === 0) {
      return false;
    }

    var selectedIndex = 0;
    var closed = true;
    var $tabContainer = $tabButtons.closest('.ct-tab-container');
    var $tabPanels = $tabContainer.find('.ct-tab-panel');
    var $tabPanelContainer = $tabPanels.closest('.ct-tab-panels');
    var tabCookieName = $tabContainer.data('tab-cookie-name');

    function resetTabsAndPanels (allowTabFocus) {
      $tabButtons.attr({
        'tabindex': '-1',
        'aria-selected': 'false'
      })//.removeClass('mtp-tab--selected');
      $tabPanels
        .attr('aria-hidden', 'true')
        .hide();
      if (allowTabFocus) {
        $tabButtons.eq(selectedIndex).attr('tabindex', '0');
      }
    }

    resetTabsAndPanels(true);

    $tabButtons.each(function () {
      var $tabButton = $(this);
      var $tabPanel = $($tabButton.attr('href'));
      $tabButton.data('ct-tab-panel', $tabPanel);
      $tabPanel.data('ct-tab', $tabButton);
    });

    $tabButtons.on('click', function (e) {
      var $tabButton = $(this);
      var $tabPanel = $tabButton.data('ct-tab-panel');
      var wasSelected = $tabButton.attr('aria-selected');

      resetTabsAndPanels(wasSelected);

      $tabButton.focus();
      if (wasSelected == 'true') {
        closed = true;
        $tabButton.attr({
          'tabindex': '0',
          'aria-selected': false
        })
        $tabContainer.addClass('ct-tab-wrapper--collapsed');
        $tabPanelContainer.attr('aria-expanded', 'false');
        //if (tabCookieName) {
        //  Cookies.remove(tabCookieName);
        //}
      } else {
        closed = false;
        selectedIndex = $tabButtons.index($tabButton);
        $tabButton.attr({
          'tabindex': '0',
          'aria-selected': true
        }).addClass('ct-tab--selected');
        $tabPanel.attr('aria-hidden', 'false');
        $tabPanel.show();
        $tabContainer.removeClass('ct-tab-wrapper--collapsed');
        $tabPanelContainer.attr('aria-expanded', 'true');
        //if (tabCookieName) {
        //  Cookies.set(tabCookieName, selectedIndex);
        //}
      }

      e.preventDefault();
    });

    $tabContainer.on('keydown', '.ct-tab', function (e) {
      var key = e.which;

      if (key < 37 || key > 40) {
        return;
      }

      var maxIndex = $tabButtons.length - 1;

      if (key === 37 || key === 38) {
        if (selectedIndex > 0) {
          selectedIndex--;
        } else {
          selectedIndex = maxIndex;
        }
      } else if (key === 39 || key === 40) {
        if (selectedIndex < maxIndex) {
          selectedIndex++;
        } else {
          selectedIndex = 0;
        }
      }

      var $tabButton = $tabButtons.eq(selectedIndex);
      $tabButton.focus();
      if (closed) {
        $tabButtons.attr('tabindex', '-1');
        $tabButton.attr('tabindex', '0');
      } else {
        $tabButton.click();
      }

      e.preventDefault();
    });

    var $tabPanelsWithErrors = $tabPanels.has('.error-message');
    $tabPanelsWithErrors.each(function () {
      var $tabPanel = $(this);
      $tabPanel.data('mtp-tab').addClass('error-message');
    });
    if ($tabPanelsWithErrors.length) {
      $tabPanelsWithErrors.first().data('mtp-tab').click();
    } //else if (tabCookieName) {
      //var lastOpenTab = parseInt(Cookies.get(tabCookieName), 10);
      //if ($.isNumeric(lastOpenTab) && lastOpenTab >= 0 && lastOpenTab < $tabButtons.length) {
      //  $tabButtons.eq(lastOpenTab).click().blur();
      //}
    //}

    $('.field-specific-error a').click(function () {
      var $errorLink = $(this);
      var $fieldLabel = $($errorLink.attr('href'));
      var $tabPanel = $fieldLabel.closest('.mtp-tabpanel');
      if ($tabPanel.is(':hidden')) {
        $tabPanel.data('mtp-tab').click();
      }
    });
  }
};

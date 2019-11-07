moj.Modules.GlobalNav = {

  open: false,

  init: function() {
    var self = this;
    $('.global-nav__menu-toggler').click(function() {
      self.open = !self.open;

      if(self.open) {
        $(this).addClass('global-nav__menu-toggler--open');
        $(this).attr('aria-expanded', 'true');
        $('#global-navigation').addClass('global-nav__container--open');
        $('#global-navigation').attr('aria-hidden', 'false');
      } else {
        $(this).removeClass('global-nav__menu-toggler--open');
        $(this).attr('aria-expanded', 'false');
        $('#global-navigation').removeClass('global-nav__container--open');
        $('#global-navigation').attr('aria-hidden', 'true');
      }
    })
  }
}

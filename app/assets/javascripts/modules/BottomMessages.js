moj.Modules.BottomMessages = {
  init: function() {
    $('.messages-list')
      .scrollTop($('.messages-list').prop('scrollHeight'));
  }
};

describe('Modules.Tabs.js', function() {
  it('should exist with expected constructures', function() {
    expect(moj.Modules.Tabs.init).toBeDefined();
    expect(moj.Modules.Tabs.bindEvents).toBeDefined();
  })


  describe('Methods', function() {
    describe('...init', function () {

      beforeEach(function () {
        spyOn(moj.Modules.Tabs, 'bindEvents');
      });

      it('should call bind events', function () {
        moj.Modules.Tabs.init();
        expect(moj.Modules.Tabs.bindEvents).toHaveBeenCalled();
      });
    })

    describe('...bindEvents', function() {
      it('quits the call if no selectors have been passed in', function(){
        var result = moj.Modules.Tabs.bindEvents();
        expect(result).toBeUndefined()
      })
    })
  })
});

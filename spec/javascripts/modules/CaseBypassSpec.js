describe('Modules.CaseBypass.js', function() {
  it('should exist with expected constructures', function() {
    expect(moj.Modules.CaseBypass.init).toBeDefined();
    expect(moj.Modules.CaseBypass.showHideBypassFields).toBeDefined();
  });


  describe('Methods', function() {
    describe('...init', function() {

      beforeEach(function() {
        spyOn(moj.Modules.CaseBypass, 'showHideBypassFields');
      });

      it('should default show/hide Bypass Reasons', function() {
        moj.Modules.CaseBypass.init();
        expect(moj.Modules.CaseBypass.showHideBypassFields).toHaveBeenCalled();
      });
    })
  })
});

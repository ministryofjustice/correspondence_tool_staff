describe('Modules.CaseClosure.js', function() {
  it('should exist with expected constructures', function() {
    expect(moj.Modules.CaseClosure.init).toBeDefined();
    expect(moj.Modules.CaseClosure.showHideRefusalReasons).toBeDefined();
    expect(moj.Modules.CaseClosure.showHideExemptions).toBeDefined();
  })


  describe('Methods', function() {
    describe('...init', function () {

      beforeEach(function () {
        spyOn(moj.Modules.CaseClosure, 'showHideRefusalReasons');
        spyOn(moj.Modules.CaseClosure, 'showHideExemptions');
      });

      it('should default show/hide Refusal Reasons', function () {
        moj.Modules.CaseClosure.init();
        expect(moj.Modules.CaseClosure.showHideRefusalReasons).toHaveBeenCalled();
      });

      it('should default show/hide Exemptions', function () {
        moj.Modules.CaseClosure.init();
        expect(moj.Modules.CaseClosure.showHideExemptions).toHaveBeenCalled();
      });
    })
  })
});

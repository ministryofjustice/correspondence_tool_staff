describe('Modules.CaseClosure.js', function() {
  it('should exist with expected constructures', function() {
    expect(moj.Modules.CaseClosure.init).toBeDefined();
    expect(moj.Modules.CaseClosure.showHideOtherGroup).toBeDefined();
    expect(moj.Modules.CaseClosure.showHideExemption).toBeDefined();
    expect(moj.Modules.CaseClosure.showHideExemptionCost).toBeDefined();

  })


  describe('Methods', function() {
    describe('...init', function () {

      beforeEach(function () {
        spyOn(moj.Modules.CaseClosure, 'showHideOtherGroup');
        spyOn(moj.Modules.CaseClosure, 'showHideExemption');
        spyOn(moj.Modules.CaseClosure, 'showHideExemptionCost');
      });

      it('should default show/hide Other Reasons', function () {
        moj.Modules.CaseClosure.init();
        expect(moj.Modules.CaseClosure.showHideOtherGroup).toHaveBeenCalled();
      });

      it('should default show/hide Exemptions', function () {
        moj.Modules.CaseClosure.init();
        expect(moj.Modules.CaseClosure.showHideExemption).toHaveBeenCalled();
      });
    })
  })
});

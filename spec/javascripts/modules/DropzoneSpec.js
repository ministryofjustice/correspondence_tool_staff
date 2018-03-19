describe('Modules.Dropzone.js', function() {
  it('should exist with expected constructures', function() {
    expect(moj.Modules.Dropzone.init).toBeDefined();
    expect(moj.Modules.Dropzone.$target).toBeDefined();
  });

  describe('moj.Modules.Dropzone.init', function(){
    var dropzone;

    beforeAll(function(){
      var body = document.getElementsByTagName('body')[0];
      var dropzoneContainer = document.createElement('div');
      dropzoneContainer.classList.add('dropzone');
      dropzoneContainer.setAttribute('data-url', window.location.href);
      dropzoneContainer.setAttribute('data-max-filesize-in-mb',20);
      //dropzoneContainer.setAttribute('data-max-filesize-in-mb',20);
      body.appendChild(dropzoneContainer);
      moj.Modules.Dropzone.init();
      dropzone = dropzoneContainer
    });

    it('should change the default error messages',function() {
      expect(dropzone.dropzone.options.dictFileTooBig)
        .toEqual('File is too big. Max file size is {{maxFilesize}}MB. We can\'t upload this file.')
    })
  })
});

describe('Modules.ExternalLinks.js', function() {
  it('should exist with expected constructures', function() {
    expect(moj.Modules.ExternalLinks.init).toBeDefined();
  });
});

var Dropzone;

moj.Modules.Dropzone = {
  removeElement: function(elements) {
    while(elements.length > 0){
        elements[0].parentNode.removeChild(elements[0]);
    }
  },
  //Store the files completed
  ctCompletedFiles: [],
  // Adds error message and styling
  addErrorToFilePreview: function(file, errorMessage) {
    var errorWrapper = file.previewElement.getElementsByClassName('dz-error-message')[0];

    // Adds red border and red text on error
    errorWrapper.classList.add('error-message');
    file.previewElement.getElementsByClassName('dz-details')[0].classList.add('form-group-error');

    // Display error message
    errorWrapper.getElementsByTagName('span')[0].innerHTML= errorMessage;
  },
  $target: {},
  init: function() {
    this.$target = $('.dropzone');
    var fileInputName = this.$target.data('file-input-name');

    Dropzone.autoDiscover = false;

    this.$target.dropzone({
      url : this.$target.data('url'),
      processFileUrl: this.$target.data('process-file-url'),
      method : 'post',
      addRemoveLinks : true,
      dictFileTooBig: "File is too big. Max file size is {{maxFilesize}}MB. We can't upload this file.",
      maxFilesize : this.$target.data('max-filesize-in-mb'),
      previewTemplate : this.$target.data('dz-template'),
      paramName : 'file',
      createImageThumbnails : false,
      acceptedFiles : this.$target.data('accepted-files'),
      attachmentType : this.$target.data('attachment-type'),
      correspondenceType : this.$target.data('correspondence-type'),
      dataType : 'XML',
      checkScanURL : this.$target.data('check-scan-url'),
      headers : { formData: this.$target.data('form-data')},
      sending : function(file, xhr, formData) {
        var s3Data = $(this.element).data('form-data');
        for (var k in s3Data) {
          if (s3Data.hasOwnProperty(k)) {
            formData.append(k , s3Data[k]);
          }
        }
      },
      error: function(file, response) {
        var removeLinkContainer = file.previewElement.getElementsByClassName('dz-remove-link');
        var removeLink = file.previewElement.getElementsByClassName('dz-remove');

        //Add error styling and messaging
        this.addErrorToFilePreview(file,response);

        ////Remove "remove" link
        this.removeElement(removeLinkContainer);
        this.removeElement(removeLink);
      },
      processing: function() {
        $('.button').prop('disabled', true);
      },
      success : function(file, response) {
        // extract key and generate URL from response
        console.log(response);
        var responseDoc = $.parseXML(response);
        var $response   = $(responseDoc);
        var key = $response.find('Key').text();
        var recordToCheck = {case_attachment: {key: key, type: 'response'} };
        // create hidden field that will be sent to the server
        var input = $('<input />', { class: 'case-uploaded-files'
          , type:'hidden'
          , name: fileInputName
          , value: key });

        file.previewElement.classList.add('dz-success');

        if (file.accepted) {
          $(file.previewElement).find('.dz-upload').css('width', '100%');
        }

        $(file.previewElement).append(input);

        moj.Modules.Dropzone.CheckForVirus(this, file, recordToCheck);
      },
      removedfile : function(file) {
        // server-side will take care of cleaning up uploads dir
        $(file.previewElement).remove();
      }
    });
  }
};

moj.Modules.Dropzone.CheckForVirus = function (dropzone, file, recordToCheck) {
  // Process the temporay uploaded file (virus scan)
  var module = this;

  $(file.previewElement).find('.dz-scanning').show().html('Scanning file for known viruses...');
  $(file.previewElement).find('.dz-remove').hide();

  $.post(dropzone.options.processFileUrl, recordToCheck,function(data){
    var uploadedFile = data;
    var checkStatusTimeOut = '';

    function checkState () {
      // It throws 404 Not Found error (if virus found) but thats OK.
      // What happens is the record in the DB is deleted so it cant be found
      $.get(uploadedFile.path, function(data){
        switch (data.state){
        case 'virus_scan_passed':
          console.log('pass');
          module.VirusTestPassed(file);
          module.allScanningFinished();
          break;
        case 'virus_scan_failed':
          module.VirusTestFailed(file, checkStatusTimeOut);
          module.allScanningFinished();
          break;
        default:
          checkStatusTimeOut = setTimeout(checkState, 1000);
        }
      });
    }
    checkState();
  });
};

moj.Modules.Dropzone.VirusTestPassed = function (file) {
  file.previewTemplate.setAttribute('virus-result', 'passed');
  this.ctCompletedFiles.push(file);
  $(file.previewElement).find('.dz-upload').css('width', '100%');
  $(file.previewElement).find('.dz-scanning').hide();
  $(file.previewElement).find('.dz-remove').show();
};


moj.Modules.Dropzone.VirusTestFailed = function (file, checkStatusTimeOut) {
  var errMsg = 'Virus found. We can\'t upload this file';

  //Add error styling and messaging
  this.addErrorToFilePreview(file,errMsg);

  $(file.previewTemplate).find('.case-uploaded-files, .dz-remove').remove();
  this.ctCompletedFiles.push(file);
  file.previewTemplate.setAttribute('virus-result', 'failed');
  $(file.previewElement).find('.dz-scanning').hide();
  clearTimeout(checkStatusTimeOut);
};

moj.Modules.Dropzone.allScanningFinished = function() {
  if(this.ctCompletedFiles.length === $('.dz-preview').length){
    $('.button').prop('disabled', false);
  }
}

moj.Modules.ExternalLinks = {
  init: function() {
    $('[rel="external"]').is(function(id, el){
      $(el).append('<span class="visuallyhidden">opens in new window</span>');
    });
  }
};

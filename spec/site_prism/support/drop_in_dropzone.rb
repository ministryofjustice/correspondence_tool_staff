module SitePrism
  module Support
    module DropInDropzone
      # Upload a file to Dropzone.js
      def drop_in_dropzone(file_path:, input_name:, container_selector:)
        # Generate a uploaded request file input selector
        execute_script <<~JS
          uploadedRequestFileInput = window.$('<input/>').attr(
            { id: 'uploadedRequestFileInput',
              name: '#{input_name}',
              type:'file' }
          ).appendTo('#{container_selector}');
        JS

        wait_until_uploaded_request_file_input_visible
        sleep 2

        # Attach the file to the uploaded request file input selector
        attach_file("uploadedRequestFileInput", file_path)

        # Add the file to a fileList array
        execute_script <<~JS
          var fileList = [uploadedRequestFileInput.get(0).files[0]];
        JS

        # Trigger the fake drop event
        execute_script <<~JS
          var e = jQuery.Event('drop', { dataTransfer : { files : [uploadedRequestFileInput.get(0).files[0]] } });
          $('.dropzone')[0].dropzone.listeners[0].events.drop(e);
        JS
      end

      def upload_file(kase:, file_path:, container_selector: ".dropzone")
        file_name = File.basename(file_path)
        execute_script <<~JS
          var fileInfo = { name: "#{file_name}",
                           size: 50000,
                           key: "uploads/#{kase.id}/#{file_name}" };
          $('#{container_selector}')[0].dropzone.emit("addedfile", fileInfo);
          $('#{container_selector}')[0].dropzone.emit("complete", fileInfo);
          var response = '<?xml version="1.0" encoding="UTF-8"?><PostResponse><Bucket>correspondence-staff-case-uploads-testing</Bucket><Key>uploads/#{kase.id}/#{file_name}</Key><ETag>"76af04e357d4d752427ca41a8fb7f0ad"</ETag></PostResponse>';
          $('#{container_selector}')[0].dropzone.emit("success", fileInfo, response);
        JS
        uploaded_request_file_inputs count: 1
      end
    end
  end
end

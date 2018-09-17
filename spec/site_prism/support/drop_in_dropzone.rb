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
    end
  end
end

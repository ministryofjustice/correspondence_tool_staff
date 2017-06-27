require 'rails_helper'

describe UploaderService do
  describe '.s3_direct_post_for_case' do
    it 'retrieves an s3 presigned post' do
      allow(CASE_UPLOADS_S3_BUCKET).to receive(:presigned_post)
                                         .and_return(:a_presigned_post)
      kase = instance_spy(Case, uploads_dir: ':id/:type')
      result = UploaderService.s3_direct_post_for_case(kase, ':type')
      expect(result).to eq :a_presigned_post
      expect(kase).to have_received(:uploads_dir).with(':type')
      expect(CASE_UPLOADS_S3_BUCKET)
        .to have_received(:presigned_post)
              .with(key: 'uploads/:id/:type/${filename}',
                    success_action_status: '201')
    end
  end
end

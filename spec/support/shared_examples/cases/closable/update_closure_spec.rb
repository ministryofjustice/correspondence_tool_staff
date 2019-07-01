require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

RSpec.shared_examples 'update closure spec' do |klass|
  describe klass do
    # @todo (mseedat-moj): Extract generic tests from Foi/Sar controllers
  end
end

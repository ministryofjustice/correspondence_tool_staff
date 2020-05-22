require "rails_helper"

# require 'extensions/string'

describe String do
  describe 'downcase_first' do
    it 'returns the string with the first letter in lowercase' do
      str = 'Hi Mum'
      expect(str.downcase_first).to eq 'hi Mum'
    end
  end
end

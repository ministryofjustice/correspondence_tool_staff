module PageObjects
  module Pages
    module Support
      def expected_case_numbers(*case_names)
        case_names.map{ |name| @setup.__send__(name) }.map(&:number)
      end
    end
  end
end


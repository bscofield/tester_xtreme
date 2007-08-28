module Viget
  module TestExtensions
    module General
      attr_reader :dynamic_tests

      private
      def klass
        self.name.sub(/Test$/, '').constantize
      end

      def add_test(name, &block)
        test_name = name.gsub(/\s+/, '_')
        @dynamic_tests ||= {}
        @dynamic_tests[test_name.to_sym] = block

        class_eval %{
          def test_#{test_name}
            self.class.dynamic_tests[:#{test_name}].call(self)
          end
        }
      end
    end
  end
end
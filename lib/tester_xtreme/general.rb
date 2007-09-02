module Viget
  module TestExtensions
    module General
      attr_reader :dynamic_tests

      private
      def klass
        klass_name = self.name.sub(/Test$/, '')
        klass_name = klass_name.sub(/.+::/, '')
        klass_name.constantize
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
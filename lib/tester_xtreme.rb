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
    
    module ActiveRecord
      def should_require(*attributes)
        attributes.each do |attr|
          error_message = "#{attr} should be required"
          add_test error_message do |myself|
            object = klass.new
            myself.instance_eval do
              assert !object.valid?, error_message
              assert object.errors.on(attr), error_message
              errors = object.errors.on(attr)
              if errors.is_a?(Array)
                assert errors.find {|err| err.include?('blank')}
              else
                assert errors.include?('blank')
              end
            end
          end
        end
      end

      def should_require_numeric(*attributes)
        object = klass.new
        attributes.each do |attr|
          add_test "#{attr} should not accept a non_numeric value" do |myself|
            object.send("#{attr}=", 'a')
            myself.assert !object.valid?, "Assigning a non-numeric value to #{attr} does not invalidate the object"
            myself.assert object.errors.on(attr), "#{attr} accepts a non-numeric value"
          end

          add_test "#{attr} should accept by a numeric value" do |myself|
            object.send("#{attr}=", 1)
            object.valid?
            myself.assert !object.errors.on(attr), "#{attr} does not accept a numeric value"
          end
        end
      end

      def should_require_unique(*attributes)
        object = klass.new
        attributes.each do |attr|
          add_test "#{attr} should not accept a non_unique value" do |myself|
            obj = klass.new
            klass.expects(:find).returns(obj)
            object.send("#{attr}=", 'a')
            myself.assert !object.valid?, "Assigning a non-unique value to #{attr} does not invalidate the object"
            myself.assert object.errors.on(attr), "#{attr} accepts a non-unique value"
          end
        end
      end

      def should_protect(*attributes)
        attributes.each do |attr|
          add_test "#{attr} should be protected" do |myself|
            myself.assert klass.protected_attributes, "#{attr} is not protected"
            myself.assert klass.protected_attributes.include?(attr), "#{attr} is not protected"
          end
        end
      end

      def should_require_confirmed; end
      def should_require_length;    end
      def should_require_formatted; end
      def should_require_inclusion; end
      def should_require_exclusion; end

      def should_have_many(*children)
        children.each do |child|
          add_association_tests(klass, :has_many, child)
        end
      end

      def should_belong_to(*parents)
        parents.each do |parent|
          add_association_tests(klass, :belongs_to, parent)
        end
      end

      def should_have_one(*children)
        children.each do |child|
          add_association_tests(klass, :has_one, child)
        end
      end

      def should_have_and_belong_to_many(*models)
        models.each do |model|
          add_association_tests(klass, :has_and_belongs_to_many, model)
        end
      end

      private
      def add_association_tests(klass, association, target)
        reflection = klass.reflections[target]

        add_test "#{klass.name} defines an association with #{target}" do |myself|
          myself.assert reflection, "Association not defined"
        end

        add_test "#{klass.name} defines a #{association} association with #{target}" do |myself|
          myself.assert_equal reflection.macro, association, "Association defined incorrectly"
        end
      end
    end
    
    module ActionController
      attr_reader :controller_options

      %w(get post put delete).each do |method|
        class_eval %{
          def should_#{method}(action, options = {}, session = {})
            @controller_options = {:method => :#{method}, :action => action, :options => options, :session => session}
            self
          end
        }
      end

      def and_assign(variable, value = nil, &block)
        method, action, options, session = extract_from_controller_options
        add_test "#{variable} should be assigned" do |myself|
          myself.instance_eval do
            send(method, action, options, session)
            assert assigns(variable), "#{variable} was not assigned"
          end
        end

        add_test "#{variable} should match expected" do |myself|
          myself.instance_eval do
            send(method, action, options, session)
            if block_given?
              assert block.call(assigns(variable)), "#{variable} does not have expected value"
            elsif !value.nil?
              if value.is_a?(Regexp)
                assert_match value, assigns(variable)
              else
                assert_equal value, assigns(variable)
              end

              assert_equal value, assigns(variable), "#{variable} does not have expected value"
            end
          end
        end if !value.nil? || block_given?

        self
      end

      def and_not_assign(variable)
        method, action, options, session = extract_from_controller_options
        add_test "#{variable} should not be assigned" do |myself|
          myself.instance_eval do
            send(method, action, options, session)
            assert assigns(variable).nil?, "#{variable} was assigned"
          end
        end

        self
      end

      def and_render(template = nil)
        method, action, options, session = extract_from_controller_options
        template ||= action
        add_test "#{method.to_s.upcase} #{action} should succeed" do |myself|
          myself.instance_eval do
            send(method, action, options, session)
            assert_response :success, "#{method.to_s.upcase} #{action} failed"
          end
        end

        add_test "#{template} should be rendered" do |myself|
          myself.instance_eval do
            send(method, action, options, session)
            assert_template template.to_s, "#{template} was not rendered"
          end
        end

        self
      end

      def and_set_flash(key, value = nil, &block)
        method, action, options, session = extract_from_controller_options
        add_test "flash for #{key} should be assigned" do |myself|
          myself.instance_eval do
            send(method, action, options, session)
            assert flash[key], "#{key} was not assigned in flash"
          end
        end

        add_test "flash #{key} should match expected" do |myself|
          myself.instance_eval do
            send(method, action, options, session)
            if block_given?
              assert block.call(flash[key]), "#{key} in flash does not have expected value"
            elsif !value.nil?
              if value.is_a?(Regexp)
                assert_match value, flash[key]
              else
                assert_equal value, flash[key]
              end
            end
          end
        end if !value.nil? || block_given?

        self
      end

      def and_redirect_to(target)
        method, action, options, session = extract_from_controller_options
        add_test "#{method.to_s.upcase} #{action} should redirect" do |myself|
          myself.instance_eval do
            send(method, action, options, session)
            assert_response :redirect, "#{method.to_s.upcase} #{action} did not redirect"
          end
        end

        add_test "#{method.to_s.upcase} #{action} should redirect to expected target" do |myself|
          myself.instance_eval do
            send(method, action, options, session)
            assert_redirected_to target
          end
        end

        self
      end

      def should_use_filter
        # not yet implemented
      end

      private
      def extract_from_controller_options()
        method = controller_options[:method]
        action = controller_options[:action]
        options = controller_options[:options]
        session = controller_options[:session]

        return method, action, options, session
      end
    end
  end
end
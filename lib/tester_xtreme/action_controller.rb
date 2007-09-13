module Viget
  module TestExtensions    
    module ActionController
      attr_reader :controller_options

      %w(get post put delete).each do |method|
        class_eval %{
          def should_#{method}(action, options = {}, session = {}, &block)
            @controller_options = {:method => :#{method}, :action => action, :options => options, :session => session, :prehook => block}
            self
          end
        }
      end

      def and_assign(variable, value = nil, &block)
        method, action, options, session, prehook = extract_from_controller_options
        add_test "#{variable} should be assigned" do |myself|
          myself.instance_eval do
            prehook.call if prehook
            send(method, action, options, session)
            assert assigns(variable), "#{variable} was not assigned"
          end
        end

        add_test "#{variable} should match expected" do |myself|
          myself.instance_eval do
            prehook.call if prehook
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
        method, action, options, session, prehook = extract_from_controller_options
        add_test "#{variable} should not be assigned" do |myself|
          myself.instance_eval do
            prehook.call if prehook
            send(method, action, options, session)
            assert assigns(variable).nil?, "#{variable} was assigned"
          end
        end

        self
      end

      def and_render(template = nil)
        method, action, options, session, prehook = extract_from_controller_options
        template ||= action
        add_test "#{method.to_s.upcase} #{action} should succeed" do |myself|
          myself.instance_eval do
            prehook.call if prehook
            send(method, action, options, session)
            assert_response :success, "#{method.to_s.upcase} #{action} failed"
          end
        end

        add_test "#{template} should be rendered" do |myself|
          myself.instance_eval do
            prehook.call if prehook
            send(method, action, options, session)
            assert_template template.to_s, "#{template} was not rendered"
          end
        end

        self
      end

      def and_set_flash(key, value = nil, &block)
        method, action, options, session, prehook = extract_from_controller_options
        add_test "flash for #{key} should be assigned" do |myself|
          myself.instance_eval do
            prehook.call if prehook
            send(method, action, options, session)
            assert flash[key], "#{key} was not assigned in flash"
          end
        end

        add_test "flash #{key} should match expected" do |myself|
          myself.instance_eval do
            prehook.call if prehook
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
        method, action, options, session, prehook = extract_from_controller_options
        add_test "#{method.to_s.upcase} #{action} should redirect" do |myself|
          myself.instance_eval do
            prehook.call if prehook
            send(method, action, options, session)
            assert_response :redirect, "#{method.to_s.upcase} #{action} did not redirect"
          end
        end

        add_test "#{method.to_s.upcase} #{action} should redirect to expected target" do |myself|
          myself.instance_eval do
            prehook.call if prehook
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
        method  = controller_options[:method]
        action  = controller_options[:action]
        options = controller_options[:options]
        session = controller_options[:session]
        block   = controller_options[:prehook]
        
        return method, action, options, session, block
      end
    end
  end
end
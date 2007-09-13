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
        method, action, *extra = extract_from_controller_options
        prehook = extra.shift
        add_test "#{variable} should be assigned in #{method} #{action}" do |myself|
          myself.instance_eval do
            prehook.call(self) if prehook
            send(method, action, *extra)
            assert assigns(variable), "#{variable} was not assigned"
          end
        end

        add_test "#{variable} should match expected in #{method} #{action}" do |myself|
          myself.instance_eval do
            prehook.call(self) if prehook
            send(method, action, *extra)
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
        method, action, *extra = extract_from_controller_options
        prehook = extra.shift
        add_test "#{variable} should not be assigned in #{method} #{action}" do |myself|
          myself.instance_eval do
            prehook.call(self) if prehook
            send(method, action, *extra)
            assert assigns(variable).nil?, "#{variable} was assigned"
          end
        end

        self
      end
      
      def and_use_filter(filter_name)
        method, action, *extra = extract_from_controller_options
        prehook = extra.shift
        add_test "#{method.to_s.upcase} #{action} should hit #{filter_name} filter" do |myself|
          klass.any_instance.expects(filter_name)
          myself.instance_eval do
            prehook.call(self) if prehook
            send(method, action, *extra)
          end
        end
        
        self
      end

      def and_render(template = nil)
        method, action, *extra = extract_from_controller_options
        prehook = extra.shift
        template ||= action
        add_test "#{method.to_s.upcase} #{action} should succeed" do |myself|
          myself.instance_eval do
            prehook.call(self) if prehook
            send(method, action, *extra)
            assert_response :success, "#{method.to_s.upcase} #{action} failed"
          end
        end

        add_test "#{template} should be rendered in #{method} #{action}" do |myself|
          myself.instance_eval do
            prehook.call(self) if prehook
            send(method, action, *extra)
            assert_template template.to_s, "#{template} was not rendered"
          end
        end

        self
      end

      def and_set_flash(key, value = nil, &block)
        method, action, *extra = extract_from_controller_options
        prehook = extra.shift
        add_test "flash for #{key} should be assigned in #{method} #{action}" do |myself|
          myself.instance_eval do
            prehook.call(self) if prehook
            send(method, action, *extra)
            assert flash[key], "#{key} was not assigned in flash"
          end
        end

        add_test "flash #{key} should match expected in #{method} #{action}" do |myself|
          myself.instance_eval do
            prehook.call(self) if prehook
            send(method, action, *extra)
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

      def and_set_session(key, value = nil, &block)
        method, action, *extra = extract_from_controller_options
        prehook = extra.shift
        add_test "session #{key} should be assigned in #{method} #{action}" do |myself|
          myself.instance_eval do
            prehook.call(self) if prehook
            send(method, action, *extra)
            assert session[key], "#{key} was not assigned in session"
          end
        end

        add_test "session #{key} should match expected in #{method} #{action}" do |myself|
          myself.instance_eval do
            prehook.call(self) if prehook
            send(method, action, *extra)
            if block_given?
              assert block.call(session[key]), "#{key} in session does not have expected value"
            elsif !value.nil?
              if value.is_a?(Regexp)
                assert_match value, session[key]
              else
                assert_equal value, session[key]
              end
            end
          end
        end if !value.nil? || block_given?

        self
      end

      def and_redirect_to(target)
        method, action, *extra = extract_from_controller_options
        prehook = extra.shift
        add_test "#{method.to_s.upcase} #{action} should redirect" do |myself|
          myself.instance_eval do
            prehook.call(self) if prehook
            send(method, action, *extra)
            assert_response :redirect, "#{method.to_s.upcase} #{action} did not redirect"
          end
        end

        add_test "#{method.to_s.upcase} #{action} should redirect to expected target" do |myself|
          myself.instance_eval do
            prehook.call(self) if prehook
            send(method, action, *extra)
            assert_redirected_to target
          end
        end

        self
      end

      private
      def extract_from_controller_options()
        method  = controller_options[:method]
        action  = controller_options[:action]
        options = controller_options[:options]
        session = controller_options[:session]
        block   = controller_options[:prehook]
        
        extra = []
        extra << block
        extra << options unless options.blank?
        extra << session unless session.blank?
        
        return method, action, *extra
      end
    end
  end
end
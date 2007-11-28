module Viget
  module TestExtensions    
    module ActionController
      module ClassMethods
        attr_reader :controller_options

        %w(get post put delete).each do |method|
          class_eval %{
            def #{method}(action, &block)
              @options = {
                :method  => :#{method}, 
                :action  => action
              }
              block.call if block_given?
              
              self
            end
          }
        end
        
        def with(params = {}, session = {}, &block)
          @options[:params]  = params
          @options[:session] = session
          block.call if block_given?
          self
        end

        def should_assign(variable, value = nil, &block)
          add_controller_test "#{variable} should be assigned in [method] [action]" do |myself|
            myself.instance_eval do
              assert assigns(variable), "#{variable} was not assigned"
            end
          end

          add_controller_test "#{variable} should match expected in [method] [action]" do |myself|
            myself.instance_eval do
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

        def should_not_assign(variable)
          add_controller_test "#{variable} should not be assigned in [method] [action]" do |myself|
            myself.instance_eval do
              assert assigns(variable).nil?, "#{variable} was assigned"
            end
          end
          self
        end

        def should_use_filter(filter_name)
          add_controller_test "[method] [action] should hit #{filter_name} filter" do |myself|
            klass.any_instance.expects(filter_name).raises(StandardError)
            myself.instance_eval do
              assert_raises(StandardError) do
                myself.send(@method, @action, @params, @session)
              end
            end
          end
          self
        end

        def should_not_use_filter(filter_name)
          add_controller_test "[method] [action] should not hit #{filter_name} filter" do |myself|
            klass.any_instance.expects(filter_name).never
            myself.instance_eval do
              myself.send(@method, @action, @params, @session)
            end
          end
          self
        end

        def should_render(template = nil)
          add_controller_test "[method] [action] should succeed" do |myself|
            myself.instance_eval do
              assert_response :success, "#{@method.to_s.upcase} #{@action}  failed"
            end
          end

          add_controller_test "correct template should be rendered in [method] [action]" do |myself|
            myself.instance_eval do
              template ||= @action
              assert_template template.to_s, "#{template} was not rendered"
            end
          end
          self
        end

        def should_set_flash(key, value = nil, &block)
          add_controller_test "flash for #{key} should be assigned in [method] [action]" do |myself|
            myself.instance_eval do
              assert flash[key], "#{key} was not assigned in flash"
            end
          end

          add_controller_test "flash #{key} should match expected in [method] [action]" do |myself|
            myself.instance_eval do
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

        def should_set_session(key, value = nil, &block)
          add_controller_test "session #{key} should be assigned in [method] [action]" do |myself|
            myself.instance_eval do
              assert session[key], "#{key} was not assigned in session"
            end
          end

          add_controller_test "session #{key} should match expected in [method] [action]" do |myself|
            myself.instance_eval do
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

        def should_redirect_to(target)
          add_controller_test "[method] [action] should redirect" do |myself|
            myself.instance_eval do
              assert_response :redirect, "#{@method.to_s.upcase} #{@action} was not a redirect"
            end
          end

          add_controller_test "[method] [action] should redirect to expected target" do |myself|
            if target.is_a?(Symbol)
              myself.instance_eval do
                assert_redirected_to target
              end
            else
              myself.instance_eval do
                assert_redirected_to eval(target)
              end
            end
          end
          self
        end

        private
        def extract_from_options()
          method  = @options[:method]
          action  = @options[:action]
          params  = @options[:params]
          session = @options[:session]
          return method, action, params, session
        end

        def add_controller_test(name, &block)
          method, action, params, session = extract_from_options

          test_name = name.gsub(/\s+/, '_').sub('[method]', method.to_s.upcase).sub('[action]', action.to_s)
          @dynamic_tests ||= {}
          @dynamic_tests[test_name.to_sym] = {
            :block   => block,
            :method  => method,
            :action  => action,
            :params  => params,
            :session => session
            }
          
          # TODO: merge passed-in session data with anything set in setup (e.g., login_as)
          class_eval %{
            def test_#{test_name}_#{@dynamic_tests.size.to_s.rjust(5, '0')}
              this_test = self.class.dynamic_tests[:#{test_name}]
              @method, @action, @params, @session = this_test[:method], this_test[:action], this_test[:params], this_test[:session]
              setup_and_submit_request(@method, @action, @params, @session)
              this_test[:block].call(self)
            end
          }
        end
      end

      module InstanceMethods
        def setup_and_submit_request(method, params, *extra)
          local_setup if respond_to?(:local_setup)
          send(method, params, *extra)
        end
      end
    end
  end
end
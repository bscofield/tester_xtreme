module Viget
  module TestExtensions
    module ActiveRecord
      module ClassMethods
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
              klass.expects(:find).at_least_once.returns(obj)
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
              myself.assert klass.protected_attributes.include?(attr.to_s), "#{attr} is not protected"
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
    end
  end
end
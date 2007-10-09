require 'tester_xtreme'

Test::Unit::TestCase.send :extend, Viget::TestExtensions::General::ClassMethods
Test::Unit::TestCase.send :extend, Viget::TestExtensions::ActionController::ClassMethods
Test::Unit::TestCase.send :extend, Viget::TestExtensions::ActiveRecord::ClassMethods

Test::Unit::TestCase.send :include, Viget::TestExtensions::ActionController::InstanceMethods
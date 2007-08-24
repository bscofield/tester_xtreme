require 'tester_xtreme'

Test::Unit::TestCase.send :extend, Viget::TestExtensions::General
Test::Unit::TestCase.send :extend, Viget::TestExtensions::ActionController
Test::Unit::TestCase.send :extend, Viget::TestExtensions::ActiveRecord

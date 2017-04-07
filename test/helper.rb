require 'simplecov'
require 'codecov'

module Helpers
	SimpleCov.start
    SimpleCov.formatter = SimpleCov::Formatter::Codecov
end
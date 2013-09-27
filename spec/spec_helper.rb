require 'ostruct'
require 'rspec'
require 'data/sample-github-responses'
require 'simplecov'
SimpleCov.start

begin
  # Coveralls is marked as an _optional_ dependency, so don't
  # throw a fit if it's not there.
  require 'coveralls'
  Coveralls.wear!
rescue LoadError
end

require 'spec'
require 'rubygems'
require 'mongo'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'mongo_scope'

Spec::Runner.configure do |config|
  
end

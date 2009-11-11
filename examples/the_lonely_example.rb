require 'rubygems'
require 'mongo'
require 'mongo_scope'

# taken from the spec
# Mongod should be running locally

# get a collection
connection = Mongo::Connection.new
db   = connection.db('ruby-mongo-test')
coll = db.collection("test")

# Add some data
coll.remove
coll.save({:first_name => 'Mike', :last_name => 'Harris', :age => 27})
coll.save({:first_name => 'Lowell', :age => 28})
coll.save({:first_name => 'Lou', :age => 27})

# using a scope helper method (find works just like the normal Mongo::Collection find)
puts coll.scope_in(:first_name => ['Mike','Lowell']).find.count # 2
puts coll.scope_gt(:age => 27).find.count # 1

# chained scopes
puts coll.scope_eq(:first_name => /^L/).scope_eq(:age => 27).find.count # 1

# the raw scope method (this is wrapped by the helper methods)
puts coll.scope(:op => '$in', :field => :first_name, :val => ['Mike','Lowell']).find.count # 2
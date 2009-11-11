require 'spec_helper'

class Object
  def to_sym_keys
    h = {}
    each { |k,v| h[k.to_sym] = v }
    h
  end
  def to_subset(h)
    h = h.to_sym_keys
    keys.each { |k| delete(k) unless h.keys.include?(k) }
    self
  end
end

describe "MongoScope" do
  before(:all) do
    @connection = Mongo::Connection.new(ENV['MONGO_RUBY_DRIVER_HOST'] || 'localhost', ENV['MONGO_RUBY_DRIVER_PORT'] || Mongo::Connection::DEFAULT_PORT)
    @db   = @connection.db('ruby-mongo-test')
    @coll = @db.collection("test")
  end
  before(:each) do
    @coll.remove
    @coll.save({:first_name => 'Mike', :last_name => 'Harris', :age => 27})
    @coll.save({:first_name => 'Lowell', :age => 28})
    @coll.save({:first_name => 'Lou', :age => 27})
  end
  it 'scope method' do
    @coll.raw_scope(:op => '$in', :field => :first_name, :val => ['Mike','Dave']).find.count.should == 1
  end
  it 'helper method - in' do
    @coll.scope_in(:first_name => ['Mike','Dave']).find.count.should == 1
  end
  it 'helper method - nin' do
    @coll.scope_nin(:first_name => ['Mike','Dave']).find.count.should == 2
  end
  it 'helper method - eq' do
    @coll.scope_eq(:first_name => 'Mike').find.count.should == 1
  end
  it 'helper method - gt' do
    @coll.scope_gt(:age => 26).find.count.should == 3
    @coll.scope_gt(:age => 27).find.count.should == 1
  end
  it 'chained scopes' do
    @coll.scope_eq(:age => 27).count.should == 2 
    @coll.scope_eq(:age => 27).scope_eq(:first_name => 'Mike').count.should == 1
    @coll.scope_eq(:first_name => /^L/).scope_gt(:age => 27).count.should == 1
  end
  it 'scope find ops' do
    scope = MongoScope::Scope.new(:op => '$in', :field => :first_name, :val => ['Mike','Dave'])
    scope.find_ops.should == {:first_name => {'$in' => ['Mike','Dave']}}
  end
  it 'scoped find_one' do
    @coll.find_one(:age => 27)['first_name'].should == 'Mike'
    @coll.scope_eq(:first_name => /^L/).find_one(:age => 27)['first_name'].should == 'Lou'
  end
  it 'scoped find_one with id' do
    mike_id = @coll.find_one(:first_name => 'Mike')['_id']
    lou_id = @coll.find_one(:first_name => 'Lou')['_id']
    @coll.find_one(mike_id)['first_name'].should == 'Mike'
    @coll.scope_eq(:first_name => /^L/).find_one(lou_id)['first_name'].should == 'Lou'
    @coll.scope_eq(:first_name => 'Mike').find_one(lou_id).should_not be
  end
  it 'should save' do
    @coll.scope_eq(:first_name => 'Mike').save(:abc => 42)
  end
  
end

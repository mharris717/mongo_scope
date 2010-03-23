require 'rubygems'
require File.join(File.dirname(__FILE__),'mongo_scope','util')

class SumBdy
  def sum_by_raw(ops)
    reduce_function = "function (obj, prev) { prev.count += (obj.#{ops[:sum_field]} ? obj.#{ops[:sum_field]} : 0); }"
    code = Mongo::Code.new(reduce_function)
    group([ops[:key]].flatten, ops[:filter]||{}, {"count" => 0},code)
  end
  def sum_by(ops)
    sum_by_raw(ops).inject({}) { |h,a| k = ops[:key]; h.merge(a[k] => a['count'])}
  end
end

class Mongo::Collection
  #include SumBy
end

module MongoScope
  module ScopeMethods
    def raw_scope(ops)
      ScopedCollection.new(ops,self)
    end
    def scope_eq(ops)
      scope_ops = {:field => ops.keys.first, :val => ops.values.first}
      ScopedCollection.new(EqScope.new(scope_ops),self)
    end
    %w(in nin gt lt gte lte ne mod all size exists).each do |op|
      define_method("scope_#{op}") do |ops|
        raw_scope(:op => "$#{op}", :field => ops.keys.first, :val => ops.values.first)
      end
    end
  end

  module CollMethods
    def count
      find.count
    end
    def to_scoped
      MongoScope::ScopedCollection.new(nil,self)
    end
  end
  
  class ScopedCursor
    attr_accessor :cursor
    include FromHash
    def each(&b)
      cursor.each do |x|
        yield(MongoRow.new(x))
      end
    end
    def method_missing(sym,*args,&b)
      cursor.send(sym,*args,&b)
    end
  end
  
  class MongoRow
    attr_accessor :h
    def initialize(h)
      @h = h
    end
    def method_missing(sym,*args,&b)
      h.send(sym,*args,&b)
    end
  end

  class ScopedCollection
    include ScopeMethods
    include CollMethods
    #include SumBy
    attr_accessor :scope_obj, :coll
    include Enumerable
    def initialize(scope_ops,coll)
      self.scope_obj = (scope_ops ? Scope.new(scope_ops) : nil)
      self.coll = coll
    end
    def scoped_ops(ops)
      return ops unless scope_obj
      ops = {'_id' => ops} unless ops.kind_of?(Hash)
      ops.merge(scope_obj.find_ops)
    end
    def find(selector={},options={})
      ScopedCursor.new(:cursor => coll.find(scoped_ops(selector),options))
    end
    def find_one(selector={},options={})
      res = coll.find_one(scoped_ops(selector),options)
      res ? MongoRow.new(res) : res
    end
    def remove(ops={})
      coll.remove(scoped_ops(ops))
    end
    def method_missing(sym,*args,&b)
      coll.send(sym,*args,&b)
    end
    def each(&b)
      coll.each(&b) #should this be scoped?
    end
    def group(k,filter,*args)
      filter = scoped_ops(filter || {})
      coll.group(k,filter,*args)
    end
  end

  class Scope
    def self.new(ops)
      ops.respond_to?(:find_ops) ? ops : super(ops)
    end
    attr_accessor :field, :op, :val
    include FromHash
    def find_ops
      {field => {op => val}}
    end
  end

  class EqScope
    attr_accessor :field, :val
    include FromHash
    def find_ops
      {field => val}
    end
  end
  
  def self.use!
    [CollMethods,ScopeMethods].each { |mod| ::Mongo::Collection.send(:include,mod) }
  end
  
  use!
end


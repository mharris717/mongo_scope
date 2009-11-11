require 'rubygems'
require File.join(File.dirname(__FILE__),'mongo_scope','util')

module MongoScope
  module ScopeMethods
    def scope(ops)
      ScopedCollection.new(ops,self)
    end
    def scope_eq(ops)
      scope_ops = {:field => ops.keys.first, :val => ops.values.first}
      ScopedCollection.new(EqScope.new(scope_ops),self)
    end
    %w(in gt lt nin).each do |op|
      define_method("scope_#{op}") do |ops|
        scope(:op => "$#{op}", :field => ops.keys.first, :val => ops.values.first)
      end
    end
  end

  module CollMethods
    def count
      find.count
    end
  end

  class ScopedCollection
    include ScopeMethods
    include CollMethods
    attr_accessor :scope_obj, :coll
    def initialize(scope_ops,coll)
      self.scope_obj = Scope.new(scope_ops)
      self.coll = coll
    end
    def scoped_ops(ops)
      ops.merge(scope_obj.find_ops)
    end
    def find(ops={})
      coll.find(scoped_ops(ops))
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


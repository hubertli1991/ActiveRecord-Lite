require_relative '02_searchable'
require 'active_support/inflector'

class AssocOptions

  attr_accessor( :primary_key, :foreign_key, :class_name )

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.model_class.table_name
  end
end

class BelongsToOptions < AssocOptions

  def initialize( assoc_name, options = {} )
    defaults = { primary_key: :id,
                 foreign_key: "#{assoc_name.to_s}_id".to_sym,
                 class_name: "#{assoc_name.to_s}".camelcase }
    defaults.keys.each do |key|
      self.send( "#{key}=", options[key] || defaults[key] )
    end
  end
end

class HasManyOptions < AssocOptions

  def initialize( assoc_name, self_class_name, options = {} )
    defaults = { primary_key: :id,
                 foreign_key: "#{self_class_name.singularize.underscore}_id".to_sym,
                 class_name: assoc_name.to_s.singularize.camelcase }
    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end
  end
end

module Associatable

  def belongs_to( name, options = {} )
    self.assoc_options[name] = BelongsToOptions.new( name, options )

    define_method(name) do
      belongs_to_options = self.class.assoc_options[name]
      foreign_key = belongs_to_options.foreign_key
      class_name = belongs_to_options.class_name

      id = self.send(foreign_key)
      class_name.constantize.find(id)
    end

  end

  def has_many( name, options = {} )
    self.assoc_options[name] = HasManyOptions.new( name, self.to_s, options )

    define_method(name) do
      has_many_options = self.class.assoc_options[name]
      primary_key = has_many_options.primary_key
      foreign_key = has_many_options.foreign_key
      class_name = has_many_options.class_name

      value = self.send( primary_key )
      params = { foreign_key => value }
      class_name.constantize.where( params )
    end

  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end

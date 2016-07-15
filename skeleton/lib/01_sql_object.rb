require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'


class SQLObject
  def self.columns
    return @columns if @columns
    columns = DBConnection.execute2(<<-SQL)
      SELECT *
      FROM  #{self.table_name}
      LIMIT 0
    SQL

    @columns = columns[0].map { |col| col.to_sym }
  end

  def self.finalize!
    self.columns.each do |col|

      define_method(col) do
        self.attributes[col]
      end

      define_method("#{col}=") do |val|
        self.attributes[col] = val
      end

    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self.to_s.tableize}"
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{self.table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map do |hash_params|
      self.new(hash_params)
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM #{self.table_name}
      WHERE id = ?
    SQL

    parse_all(result)[0]
  end

  def initialize(params = {})
    params.each do |attribute, value|
      attribute_sym = attribute.to_sym
      if self.class.columns.include?(attribute_sym)
        self.send("#{attribute_sym}=", value)
      else
        raise "unknown attribute 'favorite_band'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |column_name_sym| self.send(column_name_sym) }
  end

  def insert
    insert_attributes = self.class.columns[1..-1]

    column_names = insert_attributes.map { |sym| sym.to_s }
    column_names_string = column_names.join(', ')

    question_marks = column_names.map { |col| '?' }
    question_marks_string = question_marks.join(', ')

    DBConnection.execute(<<-SQL, *attribute_values[1..-1])
      INSERT INTO #{self.class.table_name} (#{column_names_string})
      VALUES (#{question_marks_string})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    question_marks = self.class.columns.map { |col| "#{col} = ?" }
    question_marks_string = question_marks.join(', ')

    DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE #{self.class.table_name}
      SET #{question_marks_string}
      WHERE id = ?
    SQL
  end

  def save
    if self.id
      update
    else
      insert
    end
  end
end

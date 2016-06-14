require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)

    where_string_array = params.keys.map do |key|
      "#{key} = ?"
    end

    where_string = where_string_array.join(" AND ")

    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT *
      FROM #{self.table_name}
      WHERE #{where_string}
    SQL

    parse_all(results)

  end
end

class SQLObject
  extend Searchable
end

require_relative '03_associatable'

module Associatable

  def has_one_through(name, through_name, source_name)

    define_method( name ) do
      # When has_one_through is called, classes that are through_name and source_name have not been declared yet
      # Create these two option hashes insode define_method because they are not invoked when has_one_through is invoked
      through_options = self.class.assoc_options[through_name]

      source_class = through_options.class_name.constantize
      self.class.assoc_options[source_name] = source_class.assoc_options[source_name]

      source_options = self.class.assoc_options[source_name]

      source_table = source_options.class_name.constantize.table_name
      through_table = through_options.class_name.constantize.table_name
      source_foreign_key = source_options.foreign_key
      # this is the foreign_key on the through_table
      source_primary_key = source_options.primary_key

      results = DBConnection.execute(<<-SQL, id)
        SELECT #{source_table}.*
        FROM #{through_table}
        JOIN #{source_table} ON #{through_table}.#{source_foreign_key} = #{source_table}.#{source_primary_key}
        WHERE #{through_table}.id = ?
      SQL

      source_options.model_class.parse_all(results).first
    end
  end
end

module GlobalCodeGenerator
  def generate_code(table:, column:, prefix:, compcode:)
    # Find the compcode column name for this table
    compcode_column = table.column_names.find { |c| c.end_with?('_compcode') }

    last_record = table
      .where("#{compcode_column} = ?", compcode)
      .where("#{column} LIKE ?", "#{prefix}%")
      .order(Arel.sql("CAST(REPLACE(#{column}, '#{prefix}', '') AS UNSIGNED) DESC"))
      .first

    last_number = last_record.present? ? last_record.send(column).gsub(prefix, '').to_i : 0
    new_number  = last_number + 1

    "#{prefix}#{new_number.to_s.rjust(5, '0')}"
  end
end
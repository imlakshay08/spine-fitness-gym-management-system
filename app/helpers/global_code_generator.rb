module GlobalCodeGenerator
  def generate_code(table:, column:, prefix:, compcode:)
    # Find the compcode column name for this table
    compcode_column = table.column_names.find { |c| c.end_with?('_compcode') }

    # `column` and `prefix` are spliced into raw SQL below. Every caller passes
    # a literal today, but validating here means a future caller cannot turn
    # this into an injection point by passing something from params.
    raise ArgumentError, "unknown column #{column}" unless table.column_names.include?(column.to_s)
    raise ArgumentError, "invalid prefix #{prefix}"  unless prefix.to_s.match?(/\A[A-Za-z0-9_-]+\z/)

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
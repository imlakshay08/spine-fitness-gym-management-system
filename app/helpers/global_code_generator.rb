module GlobalCodeGenerator
  def generate_code(table:, column:, prefix:, compcode:)
    last_record = table.where("#{column} <> '' AND #{column} LIKE ?", "#{prefix}%")
                       .where("#{column.split('_')[0]}_compcode = ?", compcode)
                       .order("#{column} DESC").first

    if last_record.present?
      last_number = last_record.send(column).gsub(prefix, "").to_i
    else
      last_number = 0
    end

    new_number = last_number + 1
    formatted_number = new_number.to_s.rjust(5, '0')  # 5-digit padding → 00001

    "#{prefix}#{formatted_number}"
  end
end

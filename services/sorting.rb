require_relative '../init.rb'

module Sorting

  def start_sorting(symbol, value)
    if symbol == :single
      add_spreadsheet_for_single(value)
    elsif symbol == :double
      sort_multiple_titles(value)
    else
      sort_multiple_titles(value)
    end
  end

  def add_spreadsheet_for_single(spreadsheet_values)
    container = {}
    spreadsheet_values.each do |row|
      author = row.at(0)
      add_spreadsheet(author, container)
      create_titles_worksheet(row, container[:spreadsheet], :unique)
      rename_default_worksheet_in(container[:spreadsheet])
    end
  end

  def sort_multiple_titles(array)
    array.each do |dataset|
      create_spreadsheets_using(dataset)
    end
  end

  def create_spreadsheets_using(spreadsheet_values)
    minus_most_similar = add_most_similar_worksheet(spreadsheet_values)
    if minus_most_similar[:false].count == 1
      add_next_worksheet(minus_most_similar, :low_jw, :unique)
    elsif minus_most_similar[:false].count > 1
      minus_most_unique = add_next_worksheet(minus_most_similar, :low_jw, :unique)
      add_next_worksheet(minus_most_unique, :mid_jw, :lut)
    end
    rename_default_worksheet_in(minus_most_similar[:spreadsheet])
  end

  def add_next_worksheet(value_hash, distance_method, worksheet_method)
    spreadsheet = value_hash[:spreadsheet]
    if value_hash[:false].count == 1
      row = value_hash[:false]
      create_titles_worksheet(row, spreadsheet, worksheet_method)
    elsif value_hash[:false].count > 1
      rows = value_hash[:false]
      container = {:true => [], :false => [], :spreadsheet => spreadsheet }
      author_titles = build_author_titles_hash(rows)
      author_titles.each_with_object(container) do |(author, titles), hsh|
        titles_hash = build_similar_titles_using(titles, distance_method)
        segregate_by_similarity_scores(hsh, titles_hash, distance_method)
        create_worksheet_for(author, hsh, rows, worksheet_method)
      end
    end
  end

end

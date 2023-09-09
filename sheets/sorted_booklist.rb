require_relative '../init.rb'

class SortedBooklist
  include Common
  include Sorting
  include Formatter

  def build
    rows = unsorted_booklist_values
    authors = authors_in_unsorted_booklist_spreadsheet(rows)
    author_titles = titles_by_authors_in_unsorted_booklist(authors, rows)
    author_titles_array = segregate_titles_by_author(author_titles)

    author_titles_array.each_pair do |key, value|
      start_sorting(key, value)
    end
    clear_unsorted_booklist
  end

  def authors_in_unsorted_booklist_spreadsheet(list_of_rows)
    list_of_rows.collect { |row| row.at(0) }.uniq
  end

  def titles_by_authors_in_unsorted_booklist(authors_array, list_of_rows)
    authors_array.each_with_object([]) do |author_name, container|
     container.push(build_titles_by_author(author_name, list_of_rows))
    end
  end

  def build_titles_by_author(author_name, list_of_rows)
    list_of_rows.each_with_object([]) do |row, container|
      container.push(row) if row.at(0) == author_name
    end
  end

  def segregate_titles_by_author(array_of_author_titles)
    hash = {:single => [], :double => [], :triple => [], :multiple => [] }
    array_of_author_titles.each_with_object(hash) do |ary, container|
      if ary.count == 1
        container[:single].push(ary)
      elsif ary.count == 2
        container[:double].push(ary)
      elsif ary.count == 3
        container[:triple].push(ary)
      else
        container[:multiple].push(ary)
      end
    end
  end

  def clear_unsorted_booklist
    sheet_service.clear_values(
      Global.spreadsheets.unsorted_booklist_spreadsheet,
      Global.spreadsheets.unsorted_booklist_worksheet,
      Google::Apis::SheetsV4::ClearValuesRequest.new
    )
  end

  def add_most_similar_worksheet(spreadsheet_values)
    hash = {:true => [], :false => [] }
    author_titles = build_author_titles_hash(spreadsheet_values)

    author_titles.each_with_object(hash) do |(author, titles), container|
      add_spreadsheet(author, container)
      titles_hash = build_similar_titles_using(titles, :high_jw)
      segregate_by_similarity_scores(container, titles_hash, :high_jw)
      create_worksheet_for(author, container, spreadsheet_values, :similar)
    end
  end

  def build_author_titles_hash(spreadsheet_values)
    spreadsheet_values.each_with_object({}) do |row, container|
      current_author = row.at(0)
      current_book_title = row.at(1)
      if container[current_author]
        container[current_author].push(current_book_title)
      else
        container[current_author] = []
        container[current_author].push(current_book_title)
      end
    end
  end

  def build_similar_titles_using(titles_by_author, call_method)
    combination = combine_titles(titles_by_author)
    combination.each_with_object({}) do |key_values_ary, hsh|
      key = key_values_ary.at(0)
      values = key_values_ary.at(1)
      if values.count > 0
        values.each_with_object([]) do |titles, ary|
          hsh[key] = ary
          array = jw_distance(method(call_method), titles[0], titles[1])
          hsh[key].push(array)
        end
      end
    end
  end

  def combine_titles(array_of_titles)
    titles_hash = Hash[array_of_titles.collect {|str| [str, [] ] } ]
    array_of_titles.combination(2).with_object([]) do |combined, ary|
      titles_hash.keys.each do |key|
        titles_hash[key].push(combined) if combined.first == key
      end
    end
    titles_hash
  end

  def jw_distance(callback, first_title, second_title)
    callback.call(first_title, second_title)
  end

  def high_jw(first_title, second_title)
    distance = (JaroWinkler.distance first_title, second_title)
    if distance >= 0.8
      [true, distance, [first_title, second_title]]
    else
      [false, distance, [first_title, second_title]]
    end
  end

  def low_jw(first_title, second_title)
    distance = (JaroWinkler.distance first_title, second_title)
    if distance <= 0.4
      [true, distance, [first_title, second_title]]
    else
      [false, distance, [first_title, second_title]]
    end
  end

  def mid_jw(first_title, second_title)
    distance = (JaroWinkler.distance first_title, second_title)
    if (distance > 0.4) && (distance < 0.8)
      [true, distance, [first_title, second_title]]
    else
      [false, distance, [first_title, second_title]]
    end
  end

  def segregate_by_similarity_scores(container, titles, call_method)
    container[:true] = titles.each_with_object([]) do |(key, values), ary|
      values.each { |val| ary.push(val.last) if val.first == true }
    end.flatten.uniq
  end

  def create_worksheet_for(author, container, dataset, call_method)
    rows_of_interest = get_rows_of_interest(dataset, author)
    titles_of_interest = container[:true]
    selected_titles = select_titles_from(titles_of_interest, rows_of_interest)
    create_titles_worksheet(
      selected_titles, container[:spreadsheet], call_method
    )
    edit_dataset(selected_titles, dataset, container)
  end

  def get_rows_of_interest(dataset, author)
    dataset.select do |booklist_row|
      booklist_row_author = booklist_row.at(0)
      booklist_row if author == booklist_row_author
    end
  end

  def select_titles_from(titles_of_interest, rows_of_interest)
    titles_of_interest.each_with_object([]) do |title, ary|
      rows_of_interest.each do |row|
        ary.push(rows_of_interest.delete(row)) if title == row.at(1)
      end
    end
  end

  def edit_dataset(rows_added, dataset, return_hash)
    return_hash[:true] = Array.new
    return_hash[:false] = dataset - rows_added
    return_hash
  end
end

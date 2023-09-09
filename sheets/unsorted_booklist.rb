require_relative '../init.rb'

class UnsortedBooklist
  include Common

  def get_unretrieved_authors
    sheet_service.get_spreadsheet_values(
      Global.spreadsheets.unretrieved_authors_spreadsheet,
      Global.spreadsheets.unretrieved_authors_worksheet
    ).values
  end

  def author_names
    sheet_service.get_spreadsheet_values(
      Global.spreadsheets.unretrieved_authors_spreadsheet,
      Global.spreadsheets.unretrieved_writer_names
    ).values.flatten
  end

  def get_unretrieved_author_names_and_genders
    sheet_service.get_spreadsheet_values(
      Global.spreadsheets.unretrieved_authors_spreadsheet,
      Global.spreadsheets.unretrieved_authors_name_and_gender
    ).values
  end

  def get_author_country
    sheet_service.get_spreadsheet_values(
      Global.spreadsheets.unretrieved_authors_spreadsheet,
      Global.spreadsheets.unretrieved_authors_country
    ).values.flatten.uniq
  end

  def get_author_region
    sheet_service.get_spreadsheet_values(
      Global.spreadsheets.unretrieved_authors_spreadsheet,
      Global.spreadsheets.unretrieved_authors_region
    ).values.flatten.uniq
  end

  def non_fiction_genres
    ["History", "World", "Social", "Biography",
      "Social Sciences", "World Civilization", "Literary Criticism",
      "Gender Studies", "Social conditions", "Women's Rights", "Political",
      "Food Writing & Reference", "Culinary & Hospitality"
    ].map { |str| str.downcase  }
  end

  def fiction_genres
    ["Poetry", "Children's fiction", "Short Stories",
      "Literary Collections", "Fantasy & Magic", "YOUNG ADULT FICTION",
      "Juvenile fiction", "Magical Realism", "Short Story Collections",
      "African Fiction", "Fiction", "Poetry", "Drama"
    ].map { |str| str.downcase  }
  end

  def build_fiction(ary)
    if ary.first != "fiction" && (!ary.include?("fiction"))
      ary.prepend("fiction").uniq
    elsif ary.first != "fiction" && (ary.include?("fiction"))
      (ary.uniq - ["fiction"]).prepend("fiction")
    else
      ary.uniq
    end
  end

  def build_non_fiction(ary)
    if ary.first != "non-fiction" && (!ary.include?("non-fiction"))
      ary.prepend("non-fiction").uniq
    elsif ary.first != "non-fiction" && (ary.include?("non-fiction"))
      ary.uniq.delete("non-fiction").prepend("non-fiction")
    else
      ary.uniq
    end
  end

  def find_isbn_10(isbndb_hash)
    if isbndb_hash.include?(:isbn10)
      isbndb_hash.values_at(:isbn10)
    else
      [" "]
    end
  end

  def find_isbn_13(isbndb_hash)
    if isbndb_hash.include?(:isbn13)
      isbndb_hash.values_at(:isbn13)
    else
      [" "]
    end
  end

  def find_long_book_title(isbndb_hash)
    if isbndb_hash.include?(:title_long)
      title_long = isbndb_hash.values_at(:title_long)
      title_long.first == nil ? [" "] : title_long
    else
      [" "]
    end
  end

  def find_number_of_pages(isbndb_hash)
    if isbndb_hash.include?(:pages)
      pages = isbndb_hash.values_at(:pages)
      pages.first == nil ? [" "] : pages
    else
      [" "]
    end
  end

  def find_language(isbndb_hash)
    if isbndb_hash.include?(:language)
      language = isbndb_hash.values_at(:language)
      language.first == nil ? [" "] : language
    else
       [" "]
    end
  end

  def date_published(isbndb_hash)
    if isbndb_hash.include?(:date_published)
      date = isbndb_hash.values_at(:date_published)
      date.first == nil ? [" "] : date
    else
      [" "]
    end
  end

  def find_title_synopsys_image(isbndb_hash)
    isbndb_hash.values_at(:title, :synopsys, :image)
  end

  def downcase_isbn_subjects(ary)
    if ary != nil
      ary.map { |str|
        str.split(/\--(?=[\w])/)
      }.map { |ary|
        ary.map { |str|
          str.split(/\ - (?=[\w])/)
        }
      }.flatten.map { |str|
        str.split(/\&(?=[\w])/)
      }.flatten.map {
        |str| str.downcase
      }
    else
      [" "]
    end
  end

  # this might work if list of strings
  # in fiction & non_finction is expanded
  def build_genres_ary_using(ary)
    if ary != nil
      fiction = ary & fiction_genres
      non_fiction = ary & non_fiction_genres
      if non_fiction.count == 0 && fiction.count == 0
        [" ", " "]
      elsif non_fiction.count == 0 && fiction.count > 0
        build_fiction(fiction)
      elsif non_fiction.count > 0 && fiction.count == 0
        build_fiction(non_fiction)
      else
        final = fiction + non_fiction
        final.prepend(" ")
      end
    else
      [" "]
    end
  end

  def find_book_genres(isbndb_hash)
    if isbndb_hash.include?(:subjects)
      isbndb_subjects = downcase_isbn_subjects(isbndb_hash[:subjects])
      build_genres_ary_using(isbndb_subjects)
    else
      [" "]
    end
  end

  def booklist_row(hsh, name, gender, country, region)
    (find_title_synopsys_image(hsh) + find_long_book_title(hsh) +
      date_published(hsh) + find_isbn_13(hsh) + find_isbn_10(hsh) +
      find_language(hsh) + find_number_of_pages(hsh) + gender +
      country + region + find_book_genres(hsh)
    ).prepend(name)
  end

  def get_books_by_unretrieved_authors(names_genders_array)
    region = get_author_region
    country = get_author_country
    names_genders_array.each_with_object([]) do |name_gender_ary, ary|
      gender = [name_gender_ary.last]
      author_name = name_gender_ary.first
      list_of_author_books = search_isbndb_for_books_by(author_name)

      if list_of_author_books != nil
        list_of_author_books.each do |hsh|
          ary << booklist_row(hsh, author_name, gender, country, region)
        end
      else
        author_not_found(author_name, gender, country, region)
      end
    end
  end

  # Returns an array of hashes
  def search_isbndb_for_books_by(author_name)
    params = {:page => 1, :pageSize => 100}

    # below calls request(page, params = {}) in isbndb-ruby/bin/api_client
    response = isbndb_api_client.author.find(author_name, params)

    if response != nil
      get_books_by_author(response, author_name)
    end
  end

  def get_books_by_author(hsh, author_name)
    hsh[:books].uniq { |book| book[:title].capitalize }
  end

  def author_not_found(author, gender, country, region)
    values = Array.new.append(
       Array.new.append(author, gender.first, country.first, region.first)
    )

    spreadsheet_range = Google::Apis::SheetsV4::ValueRange.new(
      values: values
    )

    range_name = ["#{Global.spreadsheets.authors_not_found_worksheet}"]

    sheet_service.append_spreadsheet_value(
      Global.spreadsheets.authors_not_found_spreadsheet,
      range_name,
      spreadsheet_range,
      value_input_option: value_input_option
    )
  end

  def create_booklist
    array = get_unretrieved_author_names_and_genders
    values = get_books_by_unretrieved_authors(array)
    sheet_service.append_spreadsheet_value(
      Global.spreadsheets.unsorted_booklist_spreadsheet,
      Global.spreadsheets.unsorted_booklist_worksheet,
      Google::Apis::SheetsV4::ValueRange.new(values: values),
      value_input_option: value_input_option
    )
  end

  def move_unretrieved_authors
    sheet_service.append_spreadsheet_value(
      Global.spreadsheets.retrieved_authors_spreadsheet,
      Global.spreadsheets.retrieved_authors_worksheet,
      Google::Apis::SheetsV4::ValueRange.new(values: get_unretrieved_authors),
      value_input_option: value_input_option
    )
  end

  def clear_unretrieved_authors
    sheet_service.clear_values(
      Global.spreadsheets.unretrieved_authors_spreadsheet,
      Global.spreadsheets.unretrieved_authors_worksheet,
      Google::Apis::SheetsV4::ClearValuesRequest.new
    )
  end

  def build
    create_booklist
    move_unretrieved_authors
    clear_unretrieved_authors
  end
end

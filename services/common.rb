require_relative '../init.rb'

module Common

  def value_input_option
    "RAW"
  end

  def lut
    "LikelyUniqueTitles"
  end

  def unique
    "MostUniqueTitles"
  end

  def similar
    "MostSimilarTitles"
  end

  def isbndb_api_client
    ISBNdb::ApiClient.new(
      api_key: Global.spreadsheets.isbndb_api_key
    )
  end

  def sheet_service
    @sheet_service = Google::Apis::SheetsV4::SheetsService.new
    @sheet_service.client_options.application_name = Global.spreadsheets.application
    @sheet_service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(Global.spreadsheets.googlesheets_json_key),
      scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS
    )
    @sheet_service
  end

  def drive_service
    @drive_service = Google::Apis::DriveV3::DriveService.new
    @drive_service.client_options.application_name = Global.spreadsheets.application
    @drive_service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(Global.spreadsheets.googlesheets_json_key),
      scope: Google::Apis::DriveV3::AUTH_DRIVE
    )
    @drive_service
  end

  def booklist_headers
    [
      ["author_name", "title", "synopsis",
        "bookcover_url", "title_long",
        "published", "ISBN_13", "ISBN_10",
        "language", "pages", "gender", "region",
        "country", "genre", "sub_genre_1", "sub_genre_2"
      ]
    ]
  end

  # Returns Array of string values, EG: [['one', 'two'], ['three', 'four']]
  def unsorted_booklist_values
    sheet_service.get_spreadsheet_values(
      Global.spreadsheets.unsorted_booklist_spreadsheet,
      Global.spreadsheets.unsorted_booklist_worksheet
    ).values
  end

  def add_spreadsheet(author_name, container)
    container[:spreadsheet] = drive_service.create_file(
      new_spreadsheet_titled(author_name),
      supports_all_drives: true
    )
    format_header_row(container[:spreadsheet])
  end

  def new_spreadsheet_titled(arg)
    Google::Apis::DriveV3::File.new(
      name: arg,
      mime_type: Global.spreadsheets.mime_type,
      drive_id: Global.spreadsheets.author_titles_drive_id,
      parents:[Global.spreadsheets.author_titles_drive_id]
    )
  end

  def create_titles_worksheet(rows, spreadsheet, call_method)
    rows.prepend(booklist_headers.first)
    response = new_worksheet_using(rows.count, spreadsheet, call_method)
    color_header_row(response)
    update_worksheet_using(rows, spreadsheet, call_method)
  end

  def update_worksheet_using(rows, spreadsheet, call_method)
    add_rows_via_batch_update(rows, spreadsheet, call_method)
    move_booklist(rows)
  end

  def batch_update_sorted_booklist_titles(rows)
    sheet_service.append_spreadsheet_value(
      Global.spreadsheets.sorted_booklist_titles_spreadsheet,
      Global.spreadsheets.sorted_booklist_titles_worksheet,
      Google::Apis::SheetsV4::ValueRange.new(values: rows),
      value_input_option: value_input_option
    )
  end

  def move_booklist(rows)
    result = get_rows_to_move(rows)
    batch_update_sorted_booklist_titles(result) if result.count > 0
  end

  def get_rows_to_move(array_of_arrays)
    if array_of_arrays.first.include?(booklist_headers.first.first)
      array_of_arrays.delete_at(0)
      array_of_arrays
    else
      array_of_arrays
    end
  end

  def add_rows_via_batch_update(rows, spreadsheet, call_method)
    data = Google::Apis::SheetsV4::ValueRange.new
    data.values = rows
    data.major_dimension = 'ROWS'
    data.range = dimenstion_range(call_method).first

    request = new_update_values_request
    request.data = [data]
    request.value_input_option = value_input_option
    sheet_service.batch_update_values(spreadsheet.id, request)
  end

  def dimenstion_range(call_method)
    if call_method == :unique
      ["#{Global.spreadsheets.most_unique_titles_range}"]
    elsif call_method == :similar
      ["#{Global.spreadsheets.most_similar_titles_range}"]
    else
      ["#{Global.spreadsheets.likely_unique_titles_range}"]
    end
  end

  def rename_default_worksheet_in(spreadsheet)
    rename_worksheet(spreadsheet)
    move_default_worksheet(spreadsheet, worksheets_count(spreadsheet))
  end

  def rename_worksheet(spreadsheet)
    title = "Empty"
    requests = []
    requests.push(
      {
        update_sheet_properties: {
          properties: { sheet_id: 0, title: title },
          fields: 'title'
        }
      }
    )
    body = { requests: requests }
    sheet_service.batch_update_spreadsheet(
      spreadsheet.id, body, {}
    )
  end

  def move_default_worksheet(spreadsheet, index)
    requests = []
    requests.push(
      {
        update_sheet_properties: {
          properties: { sheet_id: 0, index: index },
          fields: 'index'
        }
      }
    )
    body = { requests: requests }
    sheet_service.batch_update_spreadsheet(
      spreadsheet.id, body, {}
    )
  end

  def worksheets_count(spreadsheet)
    sheet_service.get_spreadsheet(spreadsheet.id).sheets.count
  end
end

require_relative '../init.rb'

module Formatter

  def new_worksheet_using(row_count, spreadsheet, call_method)
    title = method(call_method).call
    column_count = booklist_headers.first.count

    sheet_request = new_add_sheet_request
    sheet_request.properties = sheet_properties
    sheet_request.properties.title = title

    grid_properties = new_grid_properties
    grid_properties.row_count = row_count + 1
    grid_properties.column_count = column_count

    grid_properties.frozen_row_count = booklist_headers.count
    sheet_request.properties.grid_properties = grid_properties

    sheet_request.properties.grid_properties = grid_properties

    request = new_batch_update_spreadsheet_request
    request.requests = new_sheet_request

    request.requests = [add_sheet: sheet_request]
    sheet_service.batch_update_spreadsheet(
      spreadsheet.id,
      request
    )
  end

  def format_header_row(new_file)
    spreadsheet_id = new_file.id
    requests = {
      requests: [
        {
          repeat_cell: {
            range: {
              sheet_id: 0,
              start_row_index: 0,
              end_row_index: 1
            },
            cell: {
              user_entered_format: {
                background_color: { red: 0.0, green: 0.4, blue: 0.0 },
                horizontal_alignment: "CENTER",
                text_format: {
                  foreground_color: {
                    red: 1.0,
                    green: 1.0,
                    blue: 1.0
                  },
                  font_size: 12,
                  bold: true
                }
              }
            },
            fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)'
          },
        },
        {
          update_sheet_properties: {
            properties: {
              sheet_id: 0,
              grid_properties: {
                frozen_row_count: 1
              }
            },
            fields: 'grid_properties.frozen_row_count'
          },
        }
      ]
    }
    sheet_service.batch_update_spreadsheet(spreadsheet_id, requests, {})
  end

  def color_header_row(batch_update_response)
    spreadsheet_id = batch_update_response.spreadsheet_id
    title = batch_update_response.replies[0].add_sheet.properties.title
    sheet_id = batch_update_response.replies[0].add_sheet.properties.sheet_id
    requests = {
      requests: [
        {
          repeat_cell: {
            range: {
              sheet_id: sheet_id,
              start_row_index: 0,
              end_row_index: 1
            },
            cell: {
              user_entered_format: {
                background_color: { red: 0.0, green: 0.4, blue: 0.0 },
                horizontal_alignment: "CENTER",
                text_format: {
                  foreground_color: {
                    red: 1.0,
                    green: 1.0,
                    blue: 1.0
                  },
                  font_size: 10,
                  bold: true
                }
              }
            },
            fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)'
          },
        }
      ]
    }
    sheet_service.batch_update_spreadsheet(spreadsheet_id, requests, {})
  end

  def new_delete_sheet_request
    Google::Apis::SheetsV4::DeleteSheetRequest.new
  end

  def new_add_sheet_request
    Google::Apis::SheetsV4::AddSheetRequest.new
  end

  def sheet_properties
     Google::Apis::SheetsV4::SheetProperties.new
  end

  def new_grid_properties
    Google::Apis::SheetsV4::GridProperties.new
  end

  def new_batch_update_spreadsheet_request
    Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new
  end

  def new_update_values_request
    Google::Apis::SheetsV4::BatchUpdateValuesRequest.new
  end

  def new_value_range_data
    Google::Apis::SheetsV4::ValueRange.new
  end

  def new_sheet_request
    Google::Apis::SheetsV4::Request.new
  end
end

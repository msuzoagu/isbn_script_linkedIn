class ISBNDBService
  attr_reader :isbn_api

  def initialize
    @isbn_api = ISBNdb::ApiClient.new(
      api_key: Global.spreadsheets.isbndb_api_key
    )
  end
end

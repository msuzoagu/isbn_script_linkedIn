require "bundler"
Bundler.require

require "json"
require "down"
require "byebug"
require "isbndb"
require "pathname"
require "optparse"
require "googleauth"
require "securerandom"
require "google/apis/drive_v3"
require "google/apis/sheets_v4"

config_directory = File.join(Dir.pwd,"config/global")

Global.configure do |config|
  config.backend :filesystem, environment: "test", path: "#{config_directory}"
end

dir_path = Pathname(__FILE__).dirname
common = dir_path + "services" + "common"
sorting = dir_path + "services" + "sorting"
formatter = dir_path + "services" + "formatter"
sorted_booklist = dir_path + "sheets" + "sorted_booklist"
unsorted_booklist = dir_path + "sheets" + "unsorted_booklist"
require_relative "#{formatter}"
require_relative "#{common}"
require_relative "#{sorting}"
require_relative "#{sorted_booklist}"
require_relative "#{unsorted_booklist}"

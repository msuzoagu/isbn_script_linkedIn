#!/usr/bin/env ruby
require_relative "./init"

options = {}

opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: opt_parser COMMAND [OPTIONS]"
  opt.separator  ""
  opt.separator  "Commands"
  opt.separator  "     createDB: create firestore database"
  opt.separator  "     updateDB: update firestore database"
  opt.separator  ""
  opt.separator  "Options"

  opt.on("-e","--environment ENVIRONMENT","which env database runs in") do |env|
    options[:environment] = env
  end

  opt.on("-d","--daemon","runing on daemon mode?") do
    options[:daemon] = true
  end

  opt.on("-h","--help","help") do
    puts opt_parser
  end
end

opt_parser.parse!

args = ARGV
case args[0]
when "retrieve_titles"
  # BookTitles.new.build
  UnsortedBooklist.new.build
when "sort_titles"
  # Booklist.new.sort
  SortedBooklist.new.build
else
  puts opt_parser
end


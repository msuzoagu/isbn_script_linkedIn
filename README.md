# Notes

Has a hard dependency on exisitng Google sheets containing the names of writers you want to retrieve. 

## Commands
- `retrieve_titles` 
  - ensure that `Unretrieved Authors` contains names of writers from a specific country (or a list of writers whom you want to retrieve) 
  - run `./cli.rb retrieve_titles`
    + populates `Unsorted BookList Titles` spreadsheet using information in `Retrieved Writers` spreadsheet

- `sort_titles`
  - run `./cli.rb sort_titles`
  	- creates a new spreadsheet for a given author and:
  		- adds a worksheet titled "MostSimilarTitles" that contains books with similar titles written by the author
  		- adds a worksheet titled "MostUniqueTitles" that contains books with unique titles written by the author
  		- adds a worksheet titled "LikelyUniqueTitles" that contains books with titles that are most likely unique written by the author 
  		- renames the default worksheet (created when new spreadsheet is created) to "Empty" and moves it to the end of the worksheets. 
    - clears `Unsorted Booklist Titles` spreadsheet
      - after each author_name spreadsheet (and relevant worksheet) is created
        - rows referring to author_name are moved from 
          `Unsorted Booklist Titles` to `Sorted Booklist Titles` 
      - `Unsorted Booklist Titles` is cleared once all rows in it are sorted
        - this is okay since `Sorted Booklist Titles` contains info from `Unsorted Booklist Titles` 

[Colors](https://github.com/gimite/google-drive-ruby/blob/master/lib/google_drive/worksheet.rb)  		
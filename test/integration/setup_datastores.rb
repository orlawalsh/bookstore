require 'sequel'
require 'sqlite3'
require_relative '../../src/book'

dBase = Sequel.sqlite(ENV['DB'])
dBase.create_table :books do
    primary_key :id
    String :isbn
    String :title
    String :author
    String :category
    Float :price
    Integer :quantity
end
books = dBase[:books] # Create a dataset
# Populate the table
books.insert(:isbn => '1111', :title => 'title1', :author => 'author1',
             :category => 'genre1', :price => 11.1, :quantity => 11 )
books.insert(:isbn => '1112', :title => 'Title 2', :author => 'Author 1',
             :category => 'Category A', :price => 12.99, :quantity => 5 )
books.insert(:isbn => '1113', :title => 'Title 3', :author => 'Author 2',
             :category => 'Category B', :price => 12.99, :quantity => 5 )


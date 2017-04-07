require_relative '../helper'
 
RSpec.configure do |c|
  c.include Helpers
end

require_relative '../../src/data_access'
require_relative '../../src/sqlite_persistence'

describe "Book update" do
   before(:each) do
      dBase = Sequel.sqlite(ENV['DB'] )
      @sqlp = SQLitePersistence.new dBase
      @memcache_client = Dalli::Client.new(ENV['MCACHE'])
      @data_access = DataAccess.new(@sqlp, @memcache_client)
      @book1 = Book.new("1111", "title1","author1", 11.1, "genre1", 11)
      @book2 = Book.new("1112", "Title 2","Author 1", 12.99, "Category A", 5)
      @data_access.startUp 
   end 
   context "required book is not in the remote cache" do
         it "should update database only" do
            @book1.category = 'category B'
            @data_access.updateBook @book1
            result = @sqlp.isbnSearch 1111
             expect(result.category).to eql 'category B'
         end
     end
     context "required book is in the remote cache" do
         before(:each) do
            @memcache_client.set "v_1112", 1
            @memcache_client.set "1112_1", @book2.to_cache
         end
         it "should get it from there" do
            @book2.category = 'category C'
            @data_access.updateBook @book2
            result = @sqlp.isbnSearch 1112
            expect(result.category).to eql 'category C'
            cache_result = Book.from_cache(@memcache_client.get("1112_2")) 
            expect(cache_result.category).to eql 'category C'
         end
     end
end
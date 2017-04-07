require_relative '../helper'
 
RSpec.configure do |c|
  c.include Helpers
end

require_relative '../../src/data_access'
require_relative '../../src/sqlite_persistence'

describe "ISBN Search fromeature" do
   before(:each) do
      dBase = Sequel.sqlite(ENV['DB'] )
      sqlp = SQLitePersistence.new dBase
      @memcache_client = Dalli::Client.new(ENV['MCACHE'])
      @memcache_client.flush      # Clear out cache for next test !!
      @data_access = DataAccess.new(sqlp, @memcache_client)
      @book1 = Book.new("1111", "title1","author1", 11.1, "genre1", 11)
      @book2 = Book.new("2222", "title2","author2", 22.2, "genre2", 22)
      @data_access.startUp 
   end  
   context "required book is not in the remote cache" do
         it "should get it from the database and put it in both caches" do
             result = @data_access.isbnSearch('1111') 
             expect(result).to eql @book1    
         end
     end
     context "required book is in the remote cache" do
         before(:each) do
            @memcache_client.set "v_2222", 1
            @memcache_client.set "2222_1", @book2.to_cache
         end
         it "should get it from there" do
             result = @data_access.isbnSearch('2222') 
             expect(result).to eql @book2    
         end
     end
     context "required book ISBN is invalid" do
         it "should return nothing" do
             result = @data_access.isbnSearch('1234') 
             expect(result).to be_nil    
         end
     end
end
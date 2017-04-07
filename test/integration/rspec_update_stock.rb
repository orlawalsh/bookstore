require_relative '../../src/data_access'
require_relative '../../src/sqlite_persistence'

describe "Update Stock feature" do
   before(:each) do
      dBase = Sequel.sqlite(ENV['DB'] )
      @sqlp = SQLitePersistence.new dBase
      @memcache_client = Dalli::Client.new(ENV['MCACHE'])
      @memcache_client.flush      # Clear out cache for next test !!
      @data_access = DataAccess.new(@sqlp, @memcache_client)
      @book1 = Book.new("1111", "title1","author1", 11.1, "genre1", 11)
      @book2 = Book.new("2222", "title2","author2", 22.2, "genre2", 22)
      @data_access.startUp 
   end  
   context "book is new" do
      it "should add it to database but leave remote cache unchanged" do
            result = @data_access.updateStock(@book2) 
             result = @sqlp.isbnSearch 2222
             expect(result.isbn).to eql '2222'
      end
   end 

   context "adding to stock of existing book on stock" do
      before(:each) do
          @book1_update = Book.new("1111", "","", 0, "", 5)
      end
      context "when it is not in the remote cache" do
         it "should leave the remote cache unchanged" do
           result = @data_access.updateStock(@book1_update) 
           result = @sqlp.isbnSearch 1111
           expect(result.quantity).to eql 16 
         end
      end

      context "when it is in the remote cache" do
         it "should update the remote cache unchanged" do
             # ..... to be completed ......
         end
      end          
   end

end
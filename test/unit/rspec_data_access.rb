require 'rspec/mocks'
require_relative '../../src/book'
require_relative '../../src/data_access'
require 'json'

describe DataAccess do
  before(:each) do
    @sqlite_database = double(:sqlite_database)
    @dalli_client = double(:dalli)
    @data_access = DataAccess.new(@sqlite_database,@dalli_client)
    @book1 = Book.new("1111", "title1","author1", 11.1, "genre1", 11)
    @book2 = Book.new("2222", "title2","author2", 22.2, "genre2", 22)
    @book3 = Book.new("3333", "title3","author1", 11.1, "genre1", 11)
    @book4 = Book.new("4444", "title4","author2", 22.2, "genre2", 22)
  end

  describe '#isbnSearch' do
     context "required book is not in the remote cache" do
         it "should get it from the database and put it in both caches" do
            expect(@sqlite_database).to receive(:isbnSearch).with('1111').and_return(@book1)
            expect(@dalli_client).to receive(:get).with('v_1111').and_return(nil)
            expect(@dalli_client).to receive(:set).with('v_1111',1)
            expect(@dalli_client).to receive(:set).with('1111_1',@book1.to_cache)
            result = @data_access.isbnSearch('1111') 
            expect(result).to eql @book1    
         end
     end
     context "required book is in the remote cache" do
         context "but not in the local cache" do
            it "should ignore the database and get it from the remote cache" do
                expect(@sqlite_database).to_not receive(:isbnSearch)
                expect(@dalli_client).to receive(:get).with('v_1111').and_return(2)
                expect(@dalli_client).to receive(:get).with('1111_2')
                          .and_return  @book1.to_cache
                result = @data_access.isbnSearch('1111') 
                expect(result).to eql(@book1)  
            end
         end
         context "and also in the local cache" do
            before(:each) do
               expect(@dalli_client).to receive(:get).with('v_1111').and_return(2)
               expect(@dalli_client).to receive(:get).with('1111_2').and_return  @book1.to_cache
               result = @data_access.isbnSearch('1111') 
            end
            it "should use the local cache's entry" do
                expect(@dalli_client).to receive(:get).with('v_1111').and_return(2)
                @result = @data_access.isbnSearch('1111') 
                expect(@result).to eql @book1  
            end
            context "but the local cache is out-of-date" do
               before(:each) do
                   @book1.quantity = 5
               end
               it "should use the remote cache's newer version" do
                   expect(@dalli_client).to receive(:get).with('v_1111').and_return(4)
                   expect(@dalli_client).to receive(:get).with('1111_4').and_return  @book1.to_cache
                   result = @data_access.isbnSearch('1111') 
                   expect(result).to eql @book1  
               end
            end             
         end  # end local cache scenarios
      end
  end

  describe '#updateBook' do
      context "ignoring the local cache " do 
        context "related book is not in the remote cache" do
          it "should update in the database only" do
            expect(@sqlite_database).to receive(:updateBook).with(@book1)
            expect(@dalli_client).to receive(:get).with("v_#{@book1.isbn}" ).
                   and_return(nil)
            @data_access.updateBook(@book1)   
         end
       end 
        context "related book is in the remote cache" do
          it "should update in the remote cache and database" do
            expect(@sqlite_database).to receive(:updateBook).with(@book1)
            expect(@dalli_client).to receive(:get).with("v_#{@book1.isbn}" ).
                   and_return(2)
            expect(@dalli_client).to receive(:set).with("v_#{@book1.isbn}",3)
            expect(@dalli_client).to receive(:set).with("#{@book1.isbn}_3",@book1.to_cache )                 
            @data_access.updateBook(@book1)   
          end
       end 
     end
     context "the local cache has the book" do 
        before(:each) do
            expect(@dalli_client).to receive(:get).with('v_1111').and_return(2)
            expect(@dalli_client).to receive(:get).with('1111_2').and_return  @book1.to_cache
            @data_access.isbnSearch('1111') 
        end     
        context "it is also in remote cache" do
          it "should update in both cache and database" do
            expect(@sqlite_database).to receive(:updateBook).with(@book1)
            expect(@dalli_client).to receive(:get).with("v_#{@book1.isbn}" ).
                   and_return(2)
            expect(@dalli_client).to receive(:set).with("v_#{@book1.isbn}",3)
            expect(@dalli_client).to receive(:set).with("#{@book1.isbn}_3",@book1.to_cache )                 
            @data_access.updateBook(@book1) 
            expect(@dalli_client).to receive(:get).with("v_#{@book1.isbn}" ).
                   and_return(3)  
             @data_access.isbnSearch(@book1.isbn)                  
           end
       end
       end        
    end

     # NEW TESTS
    describe '#updateStock' do

        context "book is new" do
          it "should add it to database but leave remote cache unchanged" do
            expect(@sqlite_database).to receive(:updateStock).with(@book2)
            expect(@dalli_client).to receive(:get).with("v_#{@book2.isbn}" ).
                   and_return(nil)
            @data_access.updateStock(@book1)   
         end
       end 
        context "related book is in the remote cache" do
          it "should update in the remote cache and database" do
            expect(@sqlite_database).to receive(:updateStock).with(@book2)
            expect(@dalli_client).to receive(:get).with("v_#{@book2.isbn}" ).
                   and_return(2)
            expect(@dalli_client).to receive(:set).with("v_#{@book2.isbn}",3)
            expect(@dalli_client).to receive(:set).with("#{@book2.isbn}_3",@book1.to_cache )                 
            @data_access.updateStock(@book1)  
    end  

end

 context "book is exisiting and in memcache" do
  it "should add to the database but also update the memcache" do
 before(:each) do
 expect(@sqlite_database).to receive(:updateStock).with(@book1).and_return(1)
  expect(@dalli_client).to receive(:get).with('v_1111').and_return(2)
expect(@dalli_client).to receive(:get).with('1111_2').and_return  @book1.to_cache
 result = @data_access.updateStock(@book1) 
 end
end
end
      end  
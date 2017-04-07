require_relative 'book'
require_relative 'local_cache'
require 'dalli'
require 'json'

  class DataAccess 
  
    def initialize database, cache  
       @database = database 
       @Remote_cache = cache   
       @local_cache = LocalCache.new
    end
    
    def startUp 
    	 @database.startUp 
    end

    def shutDown
      @database.shutDown
    end

    def isbnSearch isbn
      result = nil
      local_copy = @local_cache.get isbn
      unless local_copy
          memcache_version = @Remote_cache.get "v_#{isbn}"
          if memcache_version
             memcache_copy = @Remote_cache.get "#{isbn}_#{memcache_version}" 
             result = Book.from_cache memcache_copy
             @local_cache.set result.isbn, {book: result, version: memcache_version.to_i}       
          else 
             result = @database.isbnSearch isbn
             if result
                @Remote_cache.set "v_#{result.isbn}", 1
                @Remote_cache.set "#{result.isbn}_1", result.to_cache
                @local_cache.set result.isbn, {book: result, version: 1}
             end
          end
      else
          memcache_version = @Remote_cache.get "v_#{isbn}"
          if memcache_version.to_i == local_copy[:version]
             result = local_copy[:book]
          else 
             memcache_copy = @Remote_cache.get "#{isbn}_#{memcache_version}" 
             result = Book.from_cache memcache_copy
             @local_cache.set result.isbn, {book: result, version: memcache_version.to_i}       
          end
      end
      result
    end

    # NEW METHOD
    def updateStock book
        result = 0
        transaction_type = @database.updateStock book
        if transaction_type == 1
           memcache_version = @Remote_cache.get "v_#{book.isbn}"
           if memcache_version
             memcache_copy = @Remote_cache.get "#{book.isbn}_#{memcache_version}" 
             cache_book = Book.from_cache memcache_copy
             cache_book.quantity += book.quantity
             @Remote_cache.set "v_#{book.isbn}", memcache_version + 1
             @Remote_cache.set "#{book.isbn}_#{memcache_version + 1}", 
                   cache_book.to_cache
           end
           result = transaction_type
      end
      result
    end

    def authorSearch author

    end

    def updateBook book
      @database.updateBook book
      remote_version = @Remote_cache.get "v_#{book.isbn}"
      if remote_version
         new_version = remote_version.to_i + 1
         @Remote_cache.set "v_#{book.isbn}", new_version
         @Remote_cache.set "#{book.isbn}_#{new_version}", book.to_cache
         if @local_cache.get book.isbn
            @local_cache.set book.isbn,  {book: book, version: new_version}
         end
      end
    end

private

   def computeAuthorReport books
       result = { }
       result['books'] = 
             books.collect {|book| {'title' => book.title, 'isbn' => book.isbn } }
        result['value'] = 
             books.inject(0) {|value,book| value += book.quantity * book.price }
        result
    end

    def buildISBNVersionString isbn, book
          isbn_version = @Remote_cache.get  "v_#{isbn}"
          if isbn_version
             "#{isbn}_#{isbn_version}"
          else
             @Remote_cache.set "v_#{isbn}", 1
             (book = @database.isbnSearch isbn) unless book 
             @Remote_cache.set "#{isbn}_1", book.to_cache
             "#{isbn}_1"
          end
    end

end
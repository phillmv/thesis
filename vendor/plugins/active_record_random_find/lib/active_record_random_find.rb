module ActiveRecord
  class Base
    class << self
      def find_with_random(*args)
        if args.first.to_s == 'random'
          options = args[1]
          options = {} if options.nil?
          options[:select] = primary_key
          sql = construct_finder_sql(options)
          ids = connection.select_all(sql)
          options.delete(:select)
          find_without_random(ids[rand(ids.length)][primary_key].to_i, options)
        else
          find_without_random(*args)
        end 
      end 

      alias_method :find_without_random, :find
      alias_method :find, :find_with_random
    end
  end 
end


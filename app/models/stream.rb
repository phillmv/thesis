class Stream < ActiveRecord::Base
  set_table_name "stream"

  belongs_to :entry
  belongs_to :user

  STREAM_SIZE = 60
  
  # must end in double quotes. It turns out that connection.execute doesn't
  # let you pass in a string with ???s to be replaced, like Base.find_by_sql
  # or the conditions array. So I have to perform my own interpolation,
  # which is done lazily with an eval.
  #
  # The query explained: insert into stream all of the entries from a user's
  # subscription list (subscriptions_users) that the user has not read 
  # (i.e. do not exist in metadata) and which do not already exist in the 
  # stream.

  STREAM_REFRESH = 
    '"INSERT INTO STREAM (entry_id, user_id) SELECT e.id, su.user_id 
     FROM ENTRIES e
     JOIN SUBSCRIPTIONS_USERS su ON su.subscription_id = e.subscription_id 
                                AND su.user_id = #{value} 
     LEFT JOIN METADATA md ON md.entry_id = e.id
                        AND md.user_id = #{value}
     LEFT JOIN STREAM s ON s.entry_id = e.id
                        AND s.user_id = #{value}
        WHERE md.entry_id IS NULL
              AND s.entry_id IS NULL 
        ORDER BY e.published DESC LIMIT #{STREAM_SIZE}"'

  # Ordering this query by stream id should fix a bug I've been witnessing:

  # A user is reading entries while new entries come in and the stream 
  # gets updated. Because this query used to be ordered by published DESC,
  # the user would see repeat instances of some articles because of their
  # older publication stamps.

  # The entries were already loaded in the browser during the update cycle,
  # and they would eventually be reloaded back regardless of their read
  # state (if it got loaded between update cycles.)

  # Because of the last line in STEAM_REFRESH, the order of the stream id
  # already encodes the e.published date, while buffering articles.
  # As I introduce actual filtering, this will probably become more
  # significant.
  
  STREAM_PAGINATE = "select stream.*, entries.published from stream inner join entries on stream.entry_id = entries.id where stream.user_id = ? order by stream.id ASC"


  def self.page(user_id, page_amt, page_no)
    Stream.paginate_by_sql([STREAM_PAGINATE, user_id], {:per_page => page_amt, :page => page_no})
  end


  def self.refresh!

=begin
    # TODO: decide whether or not deletes should be grouped here or in 
    # User#read. Commented out code STINKS but this should be temporary.

    Stream.transaction do
      Stream.connection.execute("delete from stream where (select entry_id from metadata where metadata.entry_id = stream.entry_id and metadata.user_id = stream.user_id);")
    end
=end

    Stream.transaction do
      User.all.each do |u|

        if Stream.count(:conditions => "user_id = #{u.id}") < STREAM_SIZE
          Stream.connection.execute(str_rpl(STREAM_REFRESH, u.id))
        end

      end          
    end
  end

  def self.unclassified(user)
    Entry.find_by_sql(["select * from entries where (select entry_id from stream where stream.entry_id = entries.id and stream.category is null and user_id = ?)", user.id])
  end

  def self.prediction(entry, classification, user)
    stream = Stream.find_by_entry_id(entry.id)
    stream.category = classification.downcase
    stream.user_id = user.id
    stream.save!
  end


  private
  def self.str_rpl(str, value)
    eval(str)
  end

end

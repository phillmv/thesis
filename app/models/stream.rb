class Stream < ActiveRecord::Base
  set_table_name "stream"

  belongs_to :entry
  belongs_to :user

  def self.page(user_id, page_amt, page_no)
    Stream.paginate_by_sql([STREAM_PAGINATE, user_id], {:per_page => page_amt, :page => page_no})
  end


  def self.populate!

    User.all.each do |u|
      Stream.transaction do
        Stream.connection.execute(str_rpl(STREAM_POPULATE, u.id))
      end          
    end
  end

  private
  def self.str_rpl(str, *values)
    out = str
    values.each { |s| 
      out = out.sub("?", s.to_s)
    }
    return out
  end
 
  # user_id
  # Shit, it turns out that the signal value is meaningless. Hm.
  STREAM_POPULATE = 
    "INSERT INTO stream(entry_id, category, rating, user_id) 
     SELECT m.entry_id, m.category, m.signal_value, m.user_id 
     FROM metadata m 
     JOIN entries e ON m.entry_id = e.id 
     WHERE m.user_id = ? 
     AND m.read IS NULL 
     AND e.id NOT IN (SELECT s.entry_id 
            FROM stream s 
            WHERE s.user_id = m.user_id)
     ORDER BY e.published ASC"


  STREAM_PRUNE = 
    "DELETE FROM stream s
     WHERE s.user_id = ? 
     AND s.entry_id in (SELECT e.id 
            FROM entries e
            WHERE e.published < ?)"

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
  
  STREAM_PAGINATE = "select stream.*, entries.published from stream inner join entries on stream.entry_id = entries.id where stream.user_id = ? order by stream.id DESC"

end

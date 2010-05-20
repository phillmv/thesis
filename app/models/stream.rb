class Stream < ActiveRecord::Base
  set_table_name "stream"

  belongs_to :entry
  belongs_to :user

  def self.page(user_id, page_amt, page_no)
    Stream.paginate_by_sql([STREAM_PAGINATE, user_id], {:per_page => page_amt, :page => page_no})
  end


  # OK. SO. Like everything in life, there is a certain error rate in 
  # bayesian networks. It will also change as we train it with more 
  # items.
  #
  # TECHNICALLY SPEAKING, this means we can't totally trust noise NOR
  # signal ratings but eh right now with my test data it is
  # flagging 60% of entries as noise; having a lot of false positives is
  # better than a lot of false negatives.
  #
  # ERGO, why don't we have a modifier were we randomly pick x% of noisy
  # entries to be inserted into the stream alongside signal? We can then
  # slide the modifier as the error rate changes.
  #
  # I am writing this without internet at M's place while she cooks dinner,
  # and am thus lacking any means with which I can research this.
  #
  # However, I have like, a fucking degree or something? So, I
  # tried thinking about it. The principle behind a RANDOM NUMBER
  # GENERATOR is that every value it outputs is as likely to occur
  # as any other value - ignoring blah blah PRNGs are not perfect
  #
  # I used to know a lot more about these about oh six months ago
  # but it turns that the half life on what I remember from my
  # courses is perilously, criminally small. 
  #
  # Anyways, if I haven't been thinking about hard problems for a
  # while I tend to lose faith in my intuition. So I wrote a small
  # script to test this out and (accidentally) ran it a couple of 
  # million times and it turns out it works out OK over the long run.
  #
  # Also I like writing long comments. 

  def self.populate!
    User.all.each do |u|
      Stream.transaction do
        Stream.connection.execute(str_rpl(STREAM_POPULATE, u.id))

        u.unprocessed.each do |metadata|
          # what a constant mindfuck. Just calling .signal will yield
          # a ArgumentError: wrong number of arguments (1 for 0)
          # and a stack call that immediately goes into method missing.
          # I HAVE NO IDEA WTF IS GOING ON JESUS H. CHRIST
          if rand(10) >= u.attributes["modifier"]
            Stream.connection.execute(str_rpl(STREAM_INSERT, u.id, metadata.id))
          else
            Stream.connection.execute(str_rpl(METADATA_UPDATE, Metadata::SKIPPED, metadata.id))
          end
        end
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
  STREAM_POPULATE = 
    "INSERT INTO stream(entry_id, user_id, published) 
     SELECT m.entry_id, m.user_id, e.published 
     FROM metadata m 
     JOIN entries e ON m.entry_id = e.id 
     WHERE m.user_id = ? 
     AND m.read IS NULL
     AND m.signal IS TRUE
     AND e.id NOT IN (SELECT s.entry_id 
            FROM stream s 
            WHERE s.user_id = m.user_id)"

  STREAM_INSERT = 
    "INSERT INTO stream(entry_id, user_id, published)
     SELECT m.entry_id, m.user_id, e.published
     FROM metadata m
     JOIN ENTRIES e ON m.entry_id = e.id
     WHERE m.user_id = ?
     AND m.id = ?"

  METADATA_UPDATE =
    "UPDATE metadata m
     SET m.read = '?'
     WHERE m.id = ?"


  STREAM_PRUNE = 
    "DELETE FROM stream s
     WHERE s.user_id = ? 
     AND s.entry_id in (SELECT e.id 
            FROM entries e
            WHERE e.published < ?)"

  STREAM_PAGINATE = 
    "SELECT stream.* 
     FROM stream 
     WHERE stream.user_id = ? 
     ORDER BY stream.published ASC"

end

class Metadata < ActiveRecord::Base
  set_table_name "metadata"
  belongs_to :user

  # This constant defines the read value that delineates an item that has
  # been skipped from the stream, presumably for being 
  SKIPPED = "1987-06-17 05:30:00".to_datetime

  def self.populate!
    User.find_each do |u|
      Metadata.connection.execute str_rpl(METADATA_POPULATE, [u.id, u.id, 7.days.ago])
    end
    return true
  end

  def self.unclassified(user_id)
    Entry.find_by_sql([METADATA_UNCLASSIFIED, user_id])
  end

  def self.prediction(entry, classification, user)
    Metadata.transaction do
      if classification == "Liked"
        signal = 'true'
      else
        signal = 'false'
      end
      Metadata.connection.execute str_rpl(METADATA_UPDATE, [signal, entry.id, user.id])
    end
end

  private 

  
  # So. This function will slurp up all the entries that don't have
  # metadata entries from all of the subscriptions a user is subscribed to
  # if the entry pub date is at least 7 days older than the subscription
  # date.
  #
  # MySQL date functions, bitches!
  #
  # Why seven days? Because if a user is subscribing to a subscription the
  # system already knows about, they can end up with an unbounded number of
  # pre existing entries in their stream from whenever the system began 
  # following the feed. That would be lame. Ideally it would just pick off
  # the last x entries but (sigh) at the moment I think it's slightly
  # more bother than it's worth. If you want to read the past, use
  # the site's archive, I say. Right now it's just one neat SQL statement.
  #
  # TODO edge case: what if a user starts going through one of the
  # subscription index views and whats to classify an entry that lacks
  # a metadata? The like method needs to find or create some metadata.
  # 
  # Not a big deal, but untackled out of laziness at the moment (fuck).
  
  METADATA_POPULATE = 
    "INSERT INTO metadata(entry_id, user_id, created_at) 
     SELECT e.id, su.user_id, NOW() 
     FROM entries e
     JOIN subscriptions_users su ON su.user_id = ? AND e.subscription_id = su.subscription_id
     WHERE e.id NOT IN (SELECT entry_id 
            FROM metadata m 
            WHERE m.user_id = ?)
    AND e.published > SUBDATE(su.created_at, 7)"

  METADATA_UNCLASSIFIED = 
    "SELECT * FROM entries e 
     WHERE e.id IN (SELECT entry_id 
        FROM metadata m 
        WHERE m.signal IS NULL 
        AND m.read IS NULL 
        AND m.user_id = ?)"

  # TODO WARNING CODE ROT
  # I don't know why ActiveRecord attributes are not working on this model. 
  # Jesus fucking christ, what a PITA to debug. Hence, the sql.
  
  METADATA_UPDATE = 
    "UPDATE metadata m
     SET id = m.id, signal = ? 
     WHERE m.entry_id = ?
     AND m.user_id = ?"
    
  
  def self.str_rpl(str, values)
    out = str
    values.each { |s| 
      out = out.sub("?", s.to_s)
    }
    return out
  end
end

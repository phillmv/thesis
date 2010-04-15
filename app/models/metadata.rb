class Metadata < ActiveRecord::Base
  set_table_name "metadata"
  belongs_to :user

  def self.populate!
    Metadata.transaction do
      User.all.each do |u|
        Metadata.connection.execute str_rpl(METADATA_POPULATE, [u.id, u.id, 7.days.ago])
      end
    end
  end

  def self.unclassified(user_id)
    Entry.find_by_sql([METADATA_UNCLASSIFIED, user_id])
  end

  def self.prediction(entry, classification, user, values)
    Metadata.transaction do
      signalv = "%0.2f" % values["Liked"]
      noisev = "%0.2f" % values["Disliked"]
      Metadata.connection.execute str_rpl(METADATA_UPDATE, [classification, signalv, noisev, entry.id, user.id])
    end
=begin
    m = Metadata.find_by_entry_id(entry.id, :conditions => "user_id = #{user.id}")
    # I really need to find out why I can't access #category directly.
    m.attributes['category'] = classification.downcase
    m.attributes['signal_value'] = values["Liked"]
    m.attributes['noise_value'] = values["Disliked"]
    m.save!
=end
  end

  private 
  METADATA_POPULATE = 
    "INSERT INTO metadata(entry_id, user_id) 
     SELECT e.id, su.user_id 
     FROM entries e
     JOIN subscriptions_users su ON su.user_id = ? AND e.subscription_id = su.subscription_id
     WHERE e.id NOT IN (SELECT entry_id 
            FROM metadata m 
            WHERE m.user_id = ?) 
     AND e.published > '?'"

  METADATA_UNCLASSIFIED = 
    "SELECT * FROM entries e 
     WHERE e.id IN (SELECT entry_id 
        FROM metadata m 
        WHERE m.category IS NULL 
        AND m.read IS NULL 
        AND m.user_id = ?)"

  # TODO WARNING CODE ROT
  # I don't know why ActiveRecord attributes are not working on this model. 
  # Jesus fucking christ, what a PITA to debug. Hence, the sql.
  
  METADATA_UPDATE = 
    "UPDATE metadata m
     SET id = m.id, category = '?', signal_value = ?, noise_value = ?
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

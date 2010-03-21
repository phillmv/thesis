class User < ActiveRecord::Base
  has_many :metadata, :class_name => "Metadata"
  has_many :classifications
  has_and_belongs_to_many :subscriptions
  # Dunno what is up, but I'd like to get basic func in.
  acts_as_authentic do |c|
    c.login_field(:email)
    c.email_field(:email)
    c.validate_email_field(false)
  end

  def has_read?(entry)

    # cannot be arsed to do this more efficient. It eats me away inside
    # that I could save a lot of indirection and redundant obj instantiation
    # but that would involve google and messing with connection objs.
    m = Metadata.find_by_sql(["select metadata.read from metadata where metadata.user_id = ? and metadata.entry_id = ?", self.id, entry.id])
    m.first.read unless m.first.nil?
     
  end

  def read!(entry)
    Metadata.create(:entry_id => entry.id, 
                    :read => true, :user_id => self.id)
    Stream.delete_all(["entry_id = ? and user_id = ?", entry.id, self.id])
  end

  def liked!(entry)
    classify("liked", true, entry.id)
  end

  def disliked!(entry)
    classify("liked", false, entry.id)
  end

  def liked
    Entry.find_by_sql(["select * from entries e where e.id = (select c.entry_id from classifications c where e.id = c.entry_id and c.liked is true and c.user_id = ?)", self.id])
  end

  def disliked
    Entry.find_by_sql(["select * from entries e where e.id = (select c.entry_id from classifications c where e.id = c.entry_id and c.liked is false and c.user_id = ?)", self.id])
  end

  def subscribe(sub)
      self.subscriptions << sub
  end

  private
  def classify(attribute, val, entry_id)
    c = Classification.find_or_create_by_entry_id(entry_id)
    c.user = self
    c[attribute] = val
    c.save!
  end

end

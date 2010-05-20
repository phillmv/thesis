class MoveSignalToMetadata < ActiveRecord::Migration
  def self.up
    add_column :metadata, :signal, :boolean
    Metadata.all.each { |m|
      if m.category == "Liked" then
        m.signal = true
      else
        m.signal = false
      end
      m.save!
    }

    remove_column :metadata, :signal_value
    remove_column :metadata, :noise_value

  end

  def self.down
    nothing_we_can_do_really
  end
end

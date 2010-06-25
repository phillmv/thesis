class CleanDuplicates < ActiveRecord::Migration
  def self.up
    %w{metadata classifications}.each do |table|
      ActiveRecord::Base.connection.execute "delete T1 from #{table} T1, #{table} T2 where T1.user_id = T2.user_id and T1.entry_id = T2.entry_id and T1.id > T2.id" 
    end
  end

  def self.down
  end
end

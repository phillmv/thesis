class Metadata < ActiveRecord::Base
  set_table_name "metadata"
  belongs_to :user
end

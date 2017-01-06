class Jr < ApplicationRecord
  include PgSearch
  pg_search_scope :search, :against => [:name, :description]
end

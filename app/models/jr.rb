class Jr < ApplicationRecord
  include PgSearch
#  pg_search_scope :search, :against => [:name, :description], :using => [:tsearch, :trigram ]
  pg_search_scope :search, :against => [:name, :description], :using => { :tsearch => {:prefix => true, :dictionary => "english"}, :trigram => { :threshold => 0.3 }}
end

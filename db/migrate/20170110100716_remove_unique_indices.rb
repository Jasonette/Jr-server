class RemoveUniqueIndices < ActiveRecord::Migration[5.0]
  def self.up
    remove_index :jrs, :name
    remove_index :jrs, :classname
  end
  def self.down
    add_index :jrs, :name
    add_index :jrs, :classname
  end
end

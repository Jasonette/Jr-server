class ChangeVersionToString < ActiveRecord::Migration[5.0]
  def change
    change_column :jrs, :version, :string
  end
end

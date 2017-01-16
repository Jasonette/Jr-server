class ChangeVersionToV < ActiveRecord::Migration[5.0]
  def change
    rename_column :jrs, :version, :v
  end
end

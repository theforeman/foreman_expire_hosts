class AddExpiryOnToHosts < ActiveRecord::Migration[4.2]
  def change
    add_column :hosts, :expired_on, :date unless column_exists? :hosts, :expired_on
  end
end

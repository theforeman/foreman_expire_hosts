# frozen_string_literal: true

class ChangeExpiredOnType < ActiveRecord::Migration[6.0]
  def up
    change_column :hosts, :expired_on, :datetime
  end

  def down
    change_column :hosts, :expired_on, :date
  end
end

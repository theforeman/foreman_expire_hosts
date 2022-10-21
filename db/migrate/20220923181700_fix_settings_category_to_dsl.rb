# frozen_string_literal: true

class FixSettingsCategoryToDsl < ActiveRecord::Migration[6.0]
  def up
    Setting.where(category: 'Setting::ExpireHost').update_all(category: 'Setting')
  end
end

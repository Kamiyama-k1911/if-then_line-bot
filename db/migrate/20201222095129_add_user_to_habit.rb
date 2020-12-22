class AddUserToHabit < ActiveRecord::Migration[6.0]
  def change
    add_reference :habits, :user, null: false, foreign_key: true
  end
end

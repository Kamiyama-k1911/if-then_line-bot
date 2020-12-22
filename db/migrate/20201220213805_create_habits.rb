class CreateHabits < ActiveRecord::Migration[6.0]
  def change
    create_table :habits do |t|
      t.string :trigger
      t.string :action
      t.integer :count, null: false, default: 0

      t.timestamps
    end
  end
end

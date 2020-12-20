class CreateHabits < ActiveRecord::Migration[6.0]
  def change
    create_table :habits do |t|
      t.string :trigger
      t.string :action
      t.integer :count

      t.timestamps
    end
  end
end

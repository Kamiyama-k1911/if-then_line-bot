class CreateTemps < ActiveRecord::Migration[6.0]
  def change
    create_table :temps do |t|
      t.string :temp_trigger

      t.timestamps
    end
  end
end

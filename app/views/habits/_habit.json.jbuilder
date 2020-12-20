json.extract! habit, :id, :trigger, :action, :count, :created_at, :updated_at
json.url habit_url(habit, format: :json)

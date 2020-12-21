class LineBotController < ApplicationController
  require "line/bot"

  protect_from_forgery with: :null_session

  def callback
    # LINEで送られてきたメッセージのデータを取得
    body = request.body.read

    # LINE以外からリクエストが来た場合 Error を返す
    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    unless client.validate_signature(body, signature)
      head :bad_request and return
    end

    # LINEで送られてきたメッセージを適切な形式に変形
    events = client.parse_events_from(body)

    events.each do |event|
      # LINE からテキストが送信された場合
      if (event.type === Line::Bot::Event::MessageType::Text)
        message = event["message"]["text"]

        if message == "一覧"
          habit_list = "trigger一覧\n"

          # Habit.all.each.with_index(1) do |habit, index|
          #   list = "#{index}: #{habit.trigger}\n"
          #   habit_list += list
          # end

          Habit.all.each.with_index(1) do |habit, index|
            list = "#{habit.id}: #{habit.trigger}\n"
            habit_list += list
          end

         # LINE からテキストが送信されたときの処理を記述する
          reply_message = {
            type: "text",
            text: habit_list
          }
          client.reply_message(event["replyToken"], reply_message)
        elsif message.to_i != 0
          habit = Habit.find(message.to_i)

          habit.destroy

          reply_message = {
            type: "text",
            text: "番号#{habit.id}: #{habit.trigger}を削除しました！"
          }

          client.reply_message(event["replyToken"], reply_message )
          # message = {
          #   type: "text",
          #   text: "消したいtriggerの番号を指定してください！"
          # }

          # response = client.push_message(event['source']['userId'], message)
          # LINE からテキストが送信されたときの処理を記述する
        else
          #メッセージをDBに登録
          Habit.create(trigger: message)

          # LINE からテキストが送信されたときの処理を記述する
          reply_message = {
            type: "text",
            text: "trigger: #{message}を追加しました！"
          }

          client.reply_message(event["replyToken"], reply_message)
        end

      end
    end

    # LINE の webhook API との連携をするために status code 200 を返す
    render json: { status: :ok }
  end

  private

    def client
      @client ||= Line::Bot::Client.new do |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      end
    end
end
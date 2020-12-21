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

        case message
        when "一覧" then
          habit_list = "trigger\n"

          Habit.all.each.with_index(1) do |habit, index|
            list = "#{index}: #{habit.trigger}\n"
            habit_list += list
         end
          reply_message = {
            type: "text",
            text: habit_list
          }
          client.reply_message(event["replyToken"], reply_message)
        else
          Habit.create(trigger: message)

          reply_message = {
            type: "text",
            text: "trigger: #{message}を追加しました！"
          }

          client.reply_message(event["replyToken"], reply_message)
        end

        #メッセージをDBに登録

        # LINE からテキストが送信されたときの処理を記述する

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
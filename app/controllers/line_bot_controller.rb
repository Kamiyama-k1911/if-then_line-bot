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

        text =
          case message
          when "一覧"
            habits = Habit.all

            habits.each.map {|habit| "#{habit.id}: #{habit.trigger}" }.join("\n")

          when /削除+\d/
            num = message.gsub(/削除/, '').to_i

            habit = Habit.find(num)
            habit.destroy

            "trigger #{num}: #{habit.trigger}を削除しました！"
          else
            habit = Habit.create(trigger: message)

            "trigger: #{habit.trigger}を追加しました！"
          end

          # LINE からテキストが送信されたときの処理を記述する
          reply_message = {
            type: "text",
            text: text
          }
          client.reply_message(event["replyToken"], reply_message)

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
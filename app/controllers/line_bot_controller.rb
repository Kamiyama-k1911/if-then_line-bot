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
        userid = event["source"]["userId"]
        user = User.find_by(userid: userid) || User.create(userid: userid)

        message = event["message"]["text"]
        habit = nil
        text =
          case message
          when "一覧"
            habits = user.habits

            habits.each.map.with_index(1) {|habit,index| "#{index}: #{habit.trigger} 合計: #{habit.count}回" }.join("\n")

          when /削除+\d/
            num = message.gsub(/削除/, '').to_i

            habits = user.habits

            habit = habits[num-1]
            habit.destroy

            "trigger #{num}: #{habit.trigger}を削除しました！"
          when "追加"
            "triggerを入力してください！"
            # if habit == nil
              # trigger_message = {
              #   type: 'text',
              #   text: "triggerを入力してください"
              # }
              # client.push_message(userid, trigger_message)
            # end
          else
            if habit.trigger == nil && habit.action == nil
            habit = user.habits.create(trigger: trigger_message)

              action_message = {
              type: 'text',
              text: "actionを入力してください"
            }
            client.push_message(userid, action_message)

              # "trigger: #{habit.trigger}を追加しました！"
            # end
            end
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
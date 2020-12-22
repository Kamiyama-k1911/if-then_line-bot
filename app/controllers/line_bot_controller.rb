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
        text =
          case message
          when "一覧"
            habits = user.habits

            habits.each.map.with_index(1) {|habit,index| "習慣#{index} \nきっかけ:\n  #{habit.trigger} \n行動:\n  #{habit.action} \n\n行動した回数: #{habit.count}回 \n" }.join("\n")

          when /削除+\d/
            num = message.gsub(/削除/, '').to_i

            habits = user.habits

            habit = habits[num-1]
            habit.destroy

            "習慣 #{num}\n きっかけ:\n  #{habit.trigger} \n行動:\n  #{habit.action}\n\nを削除しました！"
          when /\d+回数+\d/
            binding.pry
            habit_num = message.gsub(/回数+\d/, "").to_i
            count_num = message.gsub(/\d+回数/, "").to_i

            binding.pry
            habits = user.habits

            habit = habits[habit_num-1]
            habit.count += count_num
            habit.update(count: habit.count)

            "習慣 #{habit_num}\n きっかけ:\n  #{habit.trigger} \n行動:\n  #{habit.action}\n\nを#{count_num}回行いました！合計で行った回数は#{habit.count}回です。"
          when "追加"
            "きっかけを入力してください！"
          else
            if Temp.all.length == 0
              temp_trigger = Temp.create(temp_trigger: message)

              "行動を入力してください"
            elsif Temp.all.length == 1
              temp = Temp.first
              habit = user.habits.create(trigger: temp.temp_trigger, action: message)

              temp.destroy

              "新しい習慣\n\nきっかけ:\n #{habit.trigger}  \n行動:\n  #{habit.action}\n\nを追加しました！"
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
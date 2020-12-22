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

            if habits.length == 0
              "まだ習慣は存在していません！"
            else
              habits.each.map.with_index(1) {|habit,index| "習慣#{index} \nきっかけ:\n  #{habit.trigger} \n行動:\n  #{habit.action} \n\n行動した回数: #{habit.count}回 \n" }.join("\n")
            end
          when /\d+削除/
            num = message.gsub(/削除/, '').to_i

            habits = user.habits

            habit = habits[num-1]
            habit.destroy

            "習慣 #{num}\n きっかけ:\n  #{habit.trigger} \n行動:\n  #{habit.action}\n\nを削除しました！"
          when /\d+回数+\d/
            habit_num = message.gsub(/回数+\d/, "").to_i
            count_num = message.gsub(/\d+回数/, "").to_i

            habits = user.habits

            habit = habits[habit_num-1]
            habit.count += count_num
            habit.update(count: habit.count)

            "習慣 #{habit_num}\n きっかけ:\n  #{habit.trigger} \n行動:\n  #{habit.action}\n\nを#{count_num}回行いました！合計で行った回数は#{habit.count}回です。"
          when "追加"
            "きっかけを入力してください！"
          when "使い方"
            "if-then botの機能一覧\n"+
            "__________________\n\n"+
            "1.登録した習慣を一覧表示\n2.習慣の追加\n3.習慣の削除\n4.習慣を行った回数を追加\n"+
            "__________________\n\n"+
            "1.登録した習慣を一覧表示\n"+
            "→「一覧」と入力頂きますと登録した習慣の一覧を見ることが出来ます！\n\n"+
            "2.習慣の追加\n" +
            "「追加」と入力頂きますと習慣を登録することが出来ます！\n\n" +
            "3.習慣の削除\n" +
            "「一覧で表示される習慣番号(半角)+削除」と入力頂きますと習慣を削除することが出来ます\n\n" +
            "例）3番の習慣を削除した場合は、「3削除」とご入力ください！\n\n" +
            "4.習慣を行った回数を追加\n" +
            "「一覧で表示される習慣番号(半角)+回数+追加したい回数(半角」と入力頂きますと、習慣を行った回数を追加することが出来ます\n\n" +
            "例）3番の習慣を5回行った場合は、「3回数5」とご入力ください！"
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
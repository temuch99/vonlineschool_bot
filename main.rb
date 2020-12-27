require 'telegram/bot'
require 'json'

token = '1470620452:AAEdIyQy0AAL4aIYyMO5ydVnP8dGsucsc0o'

Telegram::Bot::Client.run(token) do |bot|
  	bot.listen do |message|
  		case message
  		when Telegram::Bot::Types::Message
			case message.text
			when '/start'
				answer = "Привет, #{message.from.first_name}, я - бот, который даст тебе возможность попрактиковаться с тестовыми заданиями ЕГЭ. " +
					 	 "Введи /get для того, чтобы получить задание"
				bot.api.send_message(chat_id: message.chat.id, text: answer)
			when '/stop'
				bot.api.send_message(chat_id: message.chat.id, text: "Пока, #{message.from.first_name}, надесь еще увидимся")
			when '/get_statistic'
				bot.api.send_game(chat_id: message.chat.id, game_short_name: "statistic")
			when '/get'
				options = JSON.generate(["Ulan-Ude", "Moscow"])
				bot.api.send_poll(chat_id: message.chat.id, question: "What is the capital of Russia?",
								  options: options, correct_option_id: 0, type: "quiz",
								  is_anonymous: true, explanation: "Вы ошиблись")
			end
		when Telegram::Bot::Types::CallbackQuery
			bot.api.answer_callback_query(callback_query_id: message.id, url: "https://vonlineschool-statistic.herokuapp.com/home.html")
		when Telegram::Bot::Types::InlineQuery
		    results = [
				[1, 'First article', 'Very interesting text goes here.'],
				[2, 'Second article', 'Another interesting text here.']
		    ].map do |arr|
				Telegram::Bot::Types::InlineQueryResultArticle.new(
					id: arr[0],
					title: arr[1],
					input_message_content: Telegram::Bot::Types::InputTextMessageContent.new(message_text: arr[2])
				)
		    end

		    bot.api.answer_inline_query(inline_query_id: message.id, results: results)
		end
  	end
end
require 'telegram/bot'
require 'json'
require 'sqlite3'
require 'net/http'
require 'nokogiri'

def get_question(course_id)
	url = "https://vonlineschool.ru/api/courses/#{course_id}/questions/1"
	JSON.parse(Net::HTTP.get(URI(url)))
end

def get_courses(url="https://vonlineschool.ru/api/courses")
	JSON.parse(Net::HTTP.get(URI(url)))
end


token = '1470620452:AAEdIyQy0AAL4aIYyMO5ydVnP8dGsucsc0o'
DB = SQLite3::Database.open 'vonlineschool.db'
DB.execute "DROP TABLE user_sessions"
DB.execute "CREATE TABLE IF NOT EXISTS user_sessions(session_id INT, course TEXT)"

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
			# when '/get_statistic'
			# 	bot.api.send_game(chat_id: message.chat.id, game_short_name: "statistic")
			when '/get'
				result = DB.get_first_value "SELECT course FROM user_sessions WHERE session_id=?", message.from.id
				if result.nil?
					bot.api.send_message(chat_id: message.chat.id, text: 'Выберите курс, а потом выбирайте вопрос /get_course')
				else
					courses = get_courses()
					course = courses.find { |course| course["title"] == result }
					answers = []
					question = get_question(course["id"])
					correct_index = 0
					question["answers"].each_with_index { |answer, i| 
						answers |= [answer["answer"]]
						if answer["is_correct"] == true
							correct_index = i
						end
					}
					options = JSON.generate(answers)
					bot.api.send_photo(chat_id: message.chat.id, photo: "https://vonlineschool.ru#{question["question"]}")
					bot.api.send_poll(chat_id: message.chat.id, question: "Вопрос с идентификатором #{question["id"]}",
									  options: options, correct_option_id: 0, type: "quiz",
									  is_anonymous: true, explanation: "Вы ошиблись")
				end
			when '/get_course'
				courses = get_courses()
			    kb = courses.map do |course|
			    	Telegram::Bot::Types::InlineKeyboardButton.new(text: course["title"], callback_data: course["title"])
			    end
			    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
			    bot.api.send_message(chat_id: message.chat.id, text: 'Выберите курс', reply_markup: markup)
			end
		when Telegram::Bot::Types::CallbackQuery	
			# case message.data
			# when 'statistic'
			# 	bot.api.answer_callback_query(callback_query_id: message.id, url: "https://vonlineschool-statistic.herokuapp.com/home.html")
			# end
			courses = get_courses()
			if courses.map { |course| course["title"] }.include? message.data
				course = courses.find { |course| course["title"] == message.data}
				result = DB.get_first_value "SELECT * FROM user_sessions WHERE session_id=?", message.from.id
				if result.nil?
					DB.execute "INSERT INTO user_sessions (session_id, course) VALUES (?, ?)", message.from.id, message.data
				else
					DB.execute "UPDATE user_sessions SET course=? WHERE session_id=?", message.data, message.from.id
				end
				bot.api.send_message(chat_id: message.from.id, text: "Вы выбрали курс: #{course["title"]}, теперь нажмите /get, чтобы получить вопрос")
			end
		end
  	end
end
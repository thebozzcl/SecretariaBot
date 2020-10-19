require_relative './lib/Bot.rb'
require_relative './lib/dao/UserInfo.rb'
require_relative './lib/dao/ChatInfo.rb'
require_relative './lib/UserInfoHandler.rb'
require_relative './lib/TimezoneHandler.rb'
require 'logger'
require 'sequel'

log_out = Logger.new(STDOUT)

if ARGV.length != 2
  log_out.error('Invalid argument list, please specify your Telegram bot token and your Geonames username')
  exit(-1)
end

bot_token = ARGV[0]
geonames_username = ARGV[1]

db = Sequel.sqlite("./secretariabot.db")

chat_info = ChatInfo.new(db)
user_info = UserInfo.new(db)

user_info_handler = UserInfoHandler.new(user_info, chat_info)
timezone_handler = TimezoneHandler.new(log_out, user_info, chat_info, user_info_handler, geonames_username)

Timezone::Lookup.config(:geonames) do |c|
  c.username = geonames_username
end

Bot.new(bot_token, user_info_handler, timezone_handler, log_out)
require_relative './lib/bot.rb'
require_relative './lib/dao/user_info.rb'
require_relative './lib/dao/chat_info.rb'
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

Timezone::Lookup.config(:geonames) do |c|
  c.username = geonames_username
end

Bot.new(bot_token, geonames_username, chat_info, user_info, log_out)
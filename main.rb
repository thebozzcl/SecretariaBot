require_relative './lib/bot.rb'
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

db.create_table? :timezones do
  String :from_id, unique: false, null: false
  String :from_name, unique: false, null: false
  String :timezone, unique: false, null: false
  primary_key [:from_id], name: :id
end
timezones = db[:timezones]

db.create_table? :chat_members do
  String :chat_id, unique: false, null: false
  String :from_id, unique: false, null: false
  String :from_name, unique: false, null: false
  String :chat_title, unique: false, null: false
  primary_key [:chat_id, :from_id], name: :id
end
chat_members = db[:chat_members]

Timezone::Lookup.config(:geonames) do |c|
  c.username = 'your_geonames_username_goes_here'
end

Bot.new(bot_token, geonames_username, timezones, chat_members, log_out)
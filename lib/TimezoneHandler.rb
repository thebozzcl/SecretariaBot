require 'timezone'
require 'time'
require_relative './model/DateKey'

class TimezoneHandler
  def initialize(log_out, user_info, chat_info, user_info_handler, geonames_username)
    @log_out = log_out
    @user_info = user_info
    @chat_info = chat_info
    @user_info_handler = user_info_handler

    Timezone::Lookup.config(:geonames) do |c|
      c.username = geonames_username
    end
  end

  def request_location(bot, message)
    kb = [
      Telegram::Bot::Types::KeyboardButton.new(text: '🌐📍', request_location: true)
    ]
    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb)
    bot.api.send_message(
      chat_id: message.chat.id,
      reply_to_message_id: message.message_id,
      text: 'Para guardar tu zona horaria, necesito ver tu ubicación (*≖ᴗ≖*✿)',
      reply_markup: markup
    )
  end

  def try_extract_location(message)
    if message.location.nil?
      @log_out.info("Unexpected message: #{message.inspect}")
      return
    end
    timezone = Timezone.lookup(message.location.latitude, message.location.longitude)
    timezone_name = timezone.name
    user_name = @user_info_handler.get_username(message)
    @user_info.register_user_timezone(message.from.id, user_name, timezone_name)
    "Oki, tu zona horaria es #{timezone_name}."
  end

  def translate_date(message)
    return 'Esto no es un grupo (ఠ ͟ ಠ)' if message.chat.type == 'private'

    current_user_info = @user_info.get_user_info(message.from.id)
    return "Dile a @TheBozzUS 'Bozzolo, no funciona'" if current_user_info.nil?

    from_timezone_name = current_user_info[:timezone]
    return 'No sé dónde estás (⋟﹏⋞) Dime /guardar_zona en privado primero.' if from_timezone_name.nil?

    from_timezone = Timezone.fetch(from_timezone_name)

    command_and_args = message.text.split(' ', 2)
    if command_and_args.length < 2
      from_time_utc = Time.now.utc
    else
      begin
        from_time_utc = Time.parse("#{command_and_args[1]} #{from_timezone.abbr(Time.now)}").utc
      rescue
        return "No pude entender lo que me dijiste (⊙_☉) ¿Me pasaste una fecha y hora válidas? Dime /ayuda para ver ejemplos.'"
      end
    end

    members_list = @chat_info.get_known_chat_members(message.chat.id)
    users_info = @user_info.get_users_info(members_list)
    unknown_date_key = DateKey.new('No sé (T⌓T) ', 99_999)
    translated_dates = Hash[users_info.map do |user_info|
      user_timezone_name = user_info[:timezone]
      if user_timezone_name.nil?
        [user_info[:from_name].to_s, unknown_date_key]
      else
        to_timezone = Timezone.fetch(user_timezone_name)
        translated_date = to_timezone.utc_to_local(from_time_utc)
        [user_info[:from_name].to_s, DateKey.new(translated_date.strftime('%a %F %T'), translated_date.hour)]
      end
    end]
    return 'Nadie me ha saludado en este grupo （；・д・）' if translated_dates.values.empty?

    reversed_translated_dates = {}
    translated_dates.each do |user_name, date|
      if reversed_translated_dates.key?(date)
        reversed_translated_dates[date].append(user_name)
      else
        reversed_translated_dates[date] = [user_name]
      end
    end

    translated_dates_strings = reversed_translated_dates.sort_by{|date, _| date.hour}.to_h.map do |date, user_names|
      "#{date.date_str}: #{user_names.join(', ')}"
    end

    "• #{translated_dates_strings.join("\n• ")}"
  end
end

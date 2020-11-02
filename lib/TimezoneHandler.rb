require 'timezone'
require 'time'

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
        Telegram::Bot::Types::KeyboardButton.new(text: "🌐📍", request_location: true)
    ]
    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb)
    bot.api.send_message(
        chat_id: message.chat.id,
        reply_to_message_id: message.message_id,
        text: 'Para guardar tu zona horaria, necesito ver tu ubicación.',
        reply_markup: markup
    )
  end

  def try_extract_location(message)
    if message.location == nil
      @log_out.info("Unexpected message: #{message.inspect}")
      return
    end
    timezone = Timezone.lookup(message.location.latitude, message.location.longitude)
    timezone_name = timezone.name
    user_name = @user_info_handler.get_username(message)
    @user_info.register_user_timezone(
        message.from.id,
        user_name,
        timezone_name
    )
    return "Oki, tu zona horaria es #{timezone_name}."
  end

  def translate_date(message)
    if message.chat.type == "private"
      return "Esto no es un grupo :/"
    end
    current_user_info = @user_info.get_user_info(message.from.id)
    if current_user_info == nil
      return "Dile a @TheBozzUS 'Bozzolo, no funciona'"
    end
    from_timezone_name = current_user_info[:timezone]
    if from_timezone_name == nil
      return "No sé dónde estás :( Dime /guardar_zona en privado primero."
    end
    from_timezone = Timezone.fetch(from_timezone_name)

    command_and_args = message.text.split(" ", 2)
    if command_and_args.length < 2
      from_time_utc = Time.now.utc
    else
      begin
        from_time_utc = Time.parse("#{command_and_args[1]} #{from_timezone.abbr(Time.now)}").utc
      rescue
        return "No pude entender lo que me dijiste :( ¿Me pasaste una fecha y hora válidas? Dime /ayuda para ver ejemplos.'"
      end
    end

    members_list = @chat_info.get_known_chat_members(message.chat.id)
    translated_dates = Hash[@user_info.get_users_info(members_list).map do |user_info|
      user_timezone_name = user_info[:timezone]
      if user_timezone_name == nil
        [999, "#{user_info[:from_name]}: No sé :("]
      else
        to_timezone = Timezone.fetch(user_timezone_name)
        translated_date = to_timezone.utc_to_local(from_time_utc)
        from_name = user_info[:from_name]
        ["#{translated_date.hour}-#{from_name}", "#{from_name}: #{translated_date.strftime("%a %F %T")}"]
      end
    end]
    if translated_dates.values.empty?
      return "Nadie me ha saludado en este grupo :("
    end

    translated_dates_string = translated_dates.sort.to_h.values.join("\n• ")
    return "• #{translated_dates_string}"
  end
end

require 'telegram/bot'
require 'timezone'
require 'time'

class Bot

  def initialize (bot_token, geonames_username, chat_info, user_info, log_out)
    @chat_info = chat_info
    @user_info = user_info
    @log_out = log_out

    commands = "Puedes decirme:
      • /start o /ayuda para ver este mensaje
      • /holi o /holo
      • /mis_grupos
      • /guardar_zona
      • /mejor_no para cancelar /guardar_zona
      • /mi_zona
      • /olvidar
      • /traducir_fecha [fecha y hora local]"

    Timezone::Lookup.config(:geonames) do |c|
      c.username = geonames_username
    end

    Telegram::Bot::Client.run(bot_token) do |bot|
      bot.listen do |message|
        if message.from.is_bot == false
          case message
          when Telegram::Bot::Types::Message
            command = (message.text == nil) ? nil : message.text.split(" ")[0]
            if command != '/olvidar'
              user_name = get_user_name(message)
              @chat_info.add_chat_member(message.chat.type, message.from.id, message.chat.id)
              @user_info.register_user_info(message.from.id, user_name)
            end
            case command
            when '/start', '/ayuda'
              reply(bot, message, commands)
            when '/holi', '/holo'
              holi(bot, message)
            when '/mis_grupos'
              mis_grupos(bot, message)
            when '/guardar_zona'
              preguntar_zona(bot, message)
            when '/mejor_no'
              cancelar_preguntar_zona(bot, message)
            when '/mi_zona'
              mi_zona(bot, message)
            when '/olvidar'
              olvidar(bot, message)
            when '/traducir_fecha'
              traducir_fecha(bot, message)
            when nil
              try_extract_location(bot, message)
            else
              @log_out.info("Unexpected message: #{message.inspect}")
            end
          else
            @log_out.info("Unexpected message: #{message.inspect}")
          end
        end
      end
    end
  end

  def holi(bot, message)
    reply(bot, message, "Holi, #{message.from.first_name}.")
  end

  def mis_grupos(bot, message)
    chat_ids = @chat_info.get_known_chats_for_user(message.from.id)
    if chat_ids.empty?
      reply(bot, message, "No me has saludado en ningún grupo :(")
      return
    end

    chat_names = chat_ids.map do |chat_id|
      @chat_info.get_chat_name(bot, chat_id)
    end.to_a
    chat_names_string = chat_names.join("\n• ")
    reply(bot, message, "Tus grupos son:\n• #{chat_names_string}")
  end

  def preguntar_zona(bot, message)
    if message.chat.type != "private"
      reply(bot, message, "Nu, me da vergüenza >_< Háblame en privado.")
      return
    end
    kb = [
        Telegram::Bot::Types::KeyboardButton.new(text: "🌐📍", request_location: true)
    ]
    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb)
    bot.api.send_message(
        chat_id: message.chat.id,
        text: 'Para guardar tu zona horaria, necesito ver tu ubicación.',
        reply_markup: markup
    )
  end

  def cancelar_preguntar_zona(bot, message)
    if message.chat.type != "private"
      reply(bot, message, "Nu, me da vergüenza >_< Háblame en privado.")
      return
    end
    reply_and_clear_kb(bot, message,"Bueni.")
  end

  def try_extract_location(bot, message)
    if message.location == nil
      @log_out.info("Unexpected message: #{message.inspect}")
      return
    end
    timezone = Timezone.lookup(message.location.latitude, message.location.longitude)
    timezone_name = timezone.name
    user_name = get_user_name(message)
    @user_info.register_user_timezone(
        message.from.id,
        user_name,
        timezone_name
    )
    reply_and_clear_kb(bot, message,"Oki, tu zona horaria es #{timezone_name}.")
  end

  def mi_zona(bot, message)
    user_info = @user_info.get_user_info(message.from.id)
    if user_info == nil
      reply(bot, message, "Dile a @TheBozzUS 'Bozzolo, no funciona'")
      return
    end
    timezone = user_info[:timezone]
    if timezone != nil
      reply(bot, message, "Tu zona horaria es #{timezone}.")
    else
      reply(bot, message, "No me has dicho dónde estás :(")
    end
  end

  def olvidar(bot, message)
    @user_info.remove_user_info(message.from.id)
    @chat_info.remove_user_info(message.from.id)
    reply(bot, message, "#{message.from.first_name}, rompiste mi corazoncito :'(")
  end

  def traducir_fecha(bot, message)
    if message.chat.type == "private"
      reply(bot, message, "Esto no es un grupo :/")
      return
    end
    current_user_info = @user_info.get_user_info(message.from.id)
    if current_user_info == nil
      reply(bot, message, "Dile a @TheBozzUS 'Bozzolo, no funciona'")
      return
    end
    from_timezone_name = current_user_info[:timezone]
    if from_timezone_name == nil
      reply(bot, message, "No sé dónde estás :( Dime /guardar_zona en privado primero.")
      return
    end
    from_timezone = Timezone.fetch(from_timezone_name)

    command_and_args = message.text.split(" ", 2)
    if command_and_args.length < 2
      from_time_final = Time.now.utc
    else
      from_time_base = Time.parse("#{command_and_args[1]} UTC")
      from_dst_offset = from_timezone.dst?(from_time_base) ? 0 : 3600
      from_timezone_offset = from_timezone.utc_offset(Time.now)
      from_epoch = from_time_base.to_i - from_timezone_offset + from_dst_offset
      from_time_final = from_timezone.time_with_offset(Time.at(from_epoch))
    end

    members_list = @chat_info.get_known_chat_members(message.chat.id)
    translated_dates = @user_info.get_users_info(members_list).map do |user_info|
      user_timezone_name = user_info[:timezone]
      if user_timezone_name == nil
        "#{user_info[:from_name]}: No sé :("
      else
        to_timezone = Timezone.fetch(user_timezone_name)
        translated_date = to_timezone.utc_to_local(from_time_final.to_datetime)
        "#{user_info[:from_name]}: #{translated_date.strftime("%F %T")}"
      end
    end
    if translated_dates.empty?
      reply(bot, message, "Nadie me ha saludado en este grupo :(")
      return
    end

    translated_dates_string = translated_dates.join("\n• ")
    reply(bot, message, "• #{translated_dates_string}")
  end

  def reply(bot, message, text)
    begin
      bot.api.send_message(
          chat_id: message.chat.id,
          reply_to_message_id: message.message_id,
          text: text
      )
    rescue => error
      case error.error_code
      when nil
        return
      when "403" # Blocked
        @user_info.remove_user_info(message.from.id)
        @chat_info.remove_user_info(message.from.id)
      end
    end
  end

  def reply_and_clear_kb(bot, message, text)
    begin
      kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
      bot.api.send_message(
          chat_id: message.chat.id,
          reply_to_message_id: message.message_id,
          text: text, reply_markup: kb
      )
    rescue => error
      case error.error_code
      when nil
        return
      when "403" # Blocked
        @user_info.remove_user_info(message.from.id)
        @chat_info.remove_user_info(message.from.id)
      end
    end
  end

  def get_user_name(message)
    if message.from.username != nil
      message.from.username
    elsif message.from.first_name != nil
      message.from.first_name
    elsif message.from.last_name != nil
      message.from.last_name
    else
      "El Usuario Sin Nombre (Bozzolo, no funciona)"
    end
  end
end
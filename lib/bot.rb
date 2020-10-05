require 'telegram/bot'
require 'timezone'
require 'time'

class Bot

  def initialize (bot_token, geonames_username, timezones, chat_members, log_out)
    @timezones = timezones
    @chat_members = chat_members
    @log_out = log_out

    commands = "Puedes decirme:
      • /start o /ayuda para ver este mensaje.
      • Para manejar tus grupos:
      ◦ /holi para saludarme. Si estamos en un grupo, me voy a acordar de que eres un miembro.
      ◦ /chai para despedirse de mi. Si estamos en un grupo, me voy a olvidar de que eres un miembro.
      ◦ /mis_grupos para mostrarte en qué grupos sé que estás.
      • Para manejar tu zona horaria:
      ◦ /guardar_zona para que te pregunte tu zona horaria. Esto sólo funciona en mensajes privados.
      ◦ /listi para cerrar el cuestionario de zona horaria.
      ◦ /mi_zona para mostrar la zona horaria que tengo guardada para ti.
      ◦ /olvidar_zona para que me olvide de tu zona horaria.
      • /olvidar_todo para herir mis sentimientos.
      • Para ayudarte a manejar eventos dentro del grupo:
      ◦ /traducir_fecha [fecha y hora local] para traducir una fecha a todas las zonas horarias que tengo guardadas para el grupo."

    Timezone::Lookup.config(:geonames) do |c|
      c.username = geonames_username
    end

    Telegram::Bot::Client.run(bot_token) do |bot|
      bot.listen do |message|
        if message.from.is_bot == false
          case message
          when Telegram::Bot::Types::Message
            command = (message.text == nil) ? nil : message.text.split(" ")[0]
            case command
            when '/start', '/ayuda'
              reply(bot, message, commands)
            when '/holi'
              holi(bot, message)
            when '/chai'
              chai(bot, message)
            when '/mis_grupos'
              mis_grupos(bot, message)
            when '/guardar_zona'
              guardar_zona(bot, message)
            when '/listi'
              listi(bot, message)
            when '/mi_zona'
              mi_zona(bot, message)
            when '/olvidar_zona'
              olvidar_zona(bot, message)
            when '/olvidar_todo'
              olvidar_todo(bot, message)
            when '/traducir_fecha'
              traducir_fecha(bot, message)
            when nil
              try_extract_location(bot, message)
            else
              reply(bot, message, "No te cacho :/ #{commands}")
            end
          else
            @log_out.info("Unexpected message: #{message.inspect}")
          end
        end
      end
    end
  end

  def holi(bot, message)
    if message.chat.type != "private"
      @chat_members.insert_conflict(:replace).insert(
          :chat_id => message.chat.id,
          :from_id => message.from.id,
          :from_name => message.from.username,
          :chat_title => message.chat.title
      )
    end
    reply(bot, message, "Holi, #{message.from.first_name}.")
  end

  def chai(bot, message)
    if message.chat.type != "private"
      @chat_members.where(
          :chat_id => message.chat.id,
          :from_id => message.from.id
      ).delete
    end
    reply(bot, message,"Chai, #{message.from.first_name}.")
  end

  def mis_grupos(bot, message)
    groups = @chat_members.where(:from_id => message.from.id).map(:chat_title)
    if groups.empty?
      reply(bot, message, "No me has saludado en ningún grupo :(")
      return
    end

    groups_string = groups.join("\n• ")
    reply(bot, message, "Tus grupos son:\n• #{groups_string}"
    )
  end

  def guardar_zona(bot, message)
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
        text: 'Para guardar sus zonas horaria, necesito ver tu ubicación.',
        reply_markup: markup
    )
  end

  def try_extract_location(bot, message)
    if message.location == nil
      @log_out.info("Unexpected message: #{message.inspect}")
      return
    end
    timezone_name = Timezone.lookup(message.location.latitude, message.location.longitude).name
    @timezones.insert_conflict(:replace).insert(
        :from_id => message.from.id,
        :from_name => message.from.username,
        :timezone => timezone_name
    )
    reply_and_clear_kb(bot, message,"Oki, tu zona horaria es #{timezone_name}.")
  end

  def listi(bot, message)
    if message.chat.type != "private"
      reply(bot, message, "No sé de qué hablas <_<")
      return
    end
    reply_and_clear_kb(bot, message, "Bueni.")
  end

  def mi_zona(bot, message)
    timezone = @timezones.first(:from_id => message.from.id)
    if timezone != nil
      timezone_name = timezone[:timezone]
      reply(bot, message, "Tu zona horaria es #{timezone_name}.")
    else
      reply(bot, message, "No me has dicho dónde estás :(")
    end
  end

  def olvidar_zona(bot, message)
    @timezones.where(:from_id => message.from.id).delete
    reply(bot, message, "Puchi :( Bueno ya, me olvidé de dónde estás.")
  end

  def olvidar_todo(bot, message)
    @timezones.where(:from_id => message.from.id).delete
    @chat_members.where(:from_id => message.from.id).delete
    reply(bot, message, ":'(")
  end

  def traducir_fecha(bot, message)
    if message.chat.type == "private"
      reply(bot, message, "Esto no es un grupo :/")
      return
    end
    from_timezone_name = @timezones.first(:from_id => message.from.id)[:timezone]
    if from_timezone_name == nil
      reply(bot, message, "No sé dónde estás :( Dime /guardar_zona en privado primero.")
      return
    end
    from_timezone = Timezone.fetch(from_timezone_name)

    command_and_args = message.text.split(" ", 2)
    if command_and_args.length < 2
      reply(bot, message, "No me dijiste qué hora traducir :/")
      return
    end

    date_epoch = Time.gm(command_and_args[1]).to_i
    date_to_translate = from_timezone.local_to_utc(Time.at(date_epoch))

    members_list = @chat_members.where(:chat_id => message.chat.id).map(:from_id)
    translated_dates = @timezones.where(from_id: members_list).as_hash(:from_name, :timezone).map do |from_name, timezone|
      to_timezone = Timezone.fetch(timezone)
      translated_date = to_timezone.time_with_offset(date_to_translate)
      "#{from_name}: #{translated_date}"
    end
    if translated_dates.empty?
      reply(bot, message, "Nadie me ha saludado en este grupo :(")
      return
    end

    translated_dates_string = translated_dates.join("\n• ")
    reply(bot, message, "• #{translated_dates_string}")
  end

  def reply(bot, message, text)
    bot.api.send_message(
        chat_id: message.chat.id,
        reply_to_message_id: message.message_id,
        text: text
    )
  end

  def reply_and_clear_kb(bot, message, text)
    kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
    bot.api.send_message(
        chat_id: message.chat.id,
        reply_to_message_id: message.message_id,
        text: text, reply_markup: kb
    )
  end
end
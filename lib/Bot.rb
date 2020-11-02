require 'telegram/bot'

class Bot

  def initialize (
      bot_token,
      user_info_handler,
      timezone_handler,
      log_out
  )
    @log_out = log_out
    @user_info_handler = user_info_handler
    @timezone_handler = timezone_handler

    @commands =
"Puedes decirme:
  • /start o /ayuda para ver este mensaje
  • /holi o /holo
  • /mis_grupos
  • /guardar_zona (/mejor_no para cancelar) (sólo funciona en chats privados por temas de privacidad)
  • /mi_zona
  • /olvidar
  • /traducir_fecha [fecha y hora local, opcional]. Puedo traducir varios formatos... algunos ejemplos:
    • /traducir_fecha 2020-05-06 13:14:15
    • /traducir_fecha 15 octubre 2016
    • /traducir_fecha 5 PM
    • /traducir_fecha (si no me das una fecha, asumo que quieres la fecha actual)

Si tienes problemas, dile a @TheBozzUS 'Bozzolo, no funciona' (pero con detalles sobre cómo me mataste, por favor)."

    Telegram::Bot::Client.run(bot_token) do |bot|
      bot.listen do |message|
        process_message(bot, message)
      end
    end
  end

  def process_message(bot, message)
    if message.from.is_bot
      return
    end

    case message
    when Telegram::Bot::Types::Message
      if [2730793, 13820710, 25198635, 199948, 13076441, 82352130].include? message.from.id
        reply(bot, message, "¡Gracias por usar la versión de prueba de SecretariaBot! Tu periodo de prueba ha
terminado; para seguir usando este bot, por favor deposítale US$69.00 a @TheBozzUS.")
        return
      end
      command = (message.text == nil) ? nil : message.text.gsub("@nombri_mcnombrebot", "").split(" ")[0]
      if command != '/olvidar'
        @user_info_handler.register_user(message)
      end
      case command
      when '/start', '/ayuda'
        reply(bot, message, @commands)
      when '/holi', '/holo'
        reply(bot, message, "Holi, #{message.from.first_name}.")
      when '/mis_grupos'
        reply(bot, message, @user_info_handler.get_user_groups(bot, message))
      when '/guardar_zona'
        if require_private_chat(bot, message)
          @timezone_handler.request_location(bot, message)
        end
      when '/mejor_no'
        if require_private_chat(bot, message)
          reply_and_clear_kb(bot, message, "Bueni.")
        end
      when '/mi_zona'
        reply(bot, message, @user_info_handler.get_user_timezone(message))
      when '/olvidar'
        reply(bot, message, @user_info_handler.clear_data(message))
      when '/traducir_fecha'
        reply(bot, message, @timezone_handler.translate_date(message))
      when nil
        reply(bot, message, @timezone_handler.try_extract_location(message))
      else
        @log_out.info("Unexpected message: #{message.inspect}")
        reply(bot, message, "No sé cómo ayudarte con eso :/ " + @commands)
      end
    else
      @log_out.info("Unexpected message type: #{message.inspect}")
    end
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
      when "403" # Blocked
        @user_info_handler.clear_data(message)
      else
        @log_out.info("Unexpected error: #{error}")
      end
    end
  end

  def require_private_chat(bot, message)
    if message.chat.type != "private"
      return false
      #reply(bot, message, "Nu, me da vergüenza >_< Háblame en privado.")
      #return false
    end
    return true
  end

  def reply_and_clear_kb(bot, message, text)
    begin
      kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
      return
      bot.api.send_message(
          chat_id: message.chat.id,
          reply_to_message_id: message.message_id,
          text: text, reply_markup: kb
      )
    rescue => error
      case error.error_code
      when "403" # Blocked
        @user_info_handler.clear_data(message)
      else
        @log_out.info("Unexpected error: #{error}")
      end
    end
  end
end
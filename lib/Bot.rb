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
      "Estas son las funciones que soporto:
1. Háblame en un chat grupal para que sepa que estás ahí:
  • /start, /help o /ayuda para ver este mensaje
  • /holi o /holo
  • /mis_grupos
  • Todos los otros comandos sirven también, excepto /olvidar
2. Para registrar tu zona horaria, dime /guardar_zona (/mejor_no para cancelar). Esto sólo funciona en el chat privado conmigo.
  • Puedes decirme /mi_zona para ver qué zona horaria tengo guardada para ti
3. Para coordinar eventos en un chat grupal, dime /traducir_fecha [fecha y hora local, opcional]. Puedo traducir varios formatos. Algunos ejemplos:
  • /traducir_fecha 2020-05-06 13:14:15
  • /traducir_fecha 15 octubre 2016
  • /traducir_fecha 5 PM
  • /traducir_fecha (si no me das una fecha, asumo que quieres la fecha actual) d(>_･ )
4. Para borrar tus datos (ಥ﹏ಥ), dime /olvidar

Si quieres saber cómo funciono, o si quieres copiar mi código (*≧∀≦*), puedes encontrarlo aquí: https://github.com/thebozzcl/SecretariaBot

Si tienes preguntas, necesitas ayuda o si me matas accidentalmente （；・д・）, mándale un mensaje a @TheBozzUS diciendo 'Bozzolo, no funciona'."

    Telegram::Bot::Client.run(bot_token) do |bot|
      bot.listen do |message|
        process_message(bot, message)
      end
    end
  end

  def process_message(bot, message)
    return if message.from.is_bot

    case message
    when Telegram::Bot::Types::Message
      command = message.text.nil? ? nil : message.text.gsub('@nombri_mcnombrebot', '').split(' ')[0]
      @user_info_handler.register_user(message) if command != '/olvidar'
      case command
      when '/start', '/ayuda', '/help'
        reply(bot, message, @commands)
      when '/holi', '/holo'
        reply(bot, message, "Holi, #{message.from.first_name} (✿╹◡╹)")
      when '/mis_grupos'
        reply(bot, message, @user_info_handler.get_user_groups(bot, message))
      when '/guardar_zona'
        @timezone_handler.request_location(bot, message) if require_private_chat(bot, message)
      when '/mejor_no'
        reply_and_clear_kb(bot, message, 'Bueni ┐(´д`)┌ ') if require_private_chat(bot, message)
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
      when '403' # Blocked
        @user_info_handler.clear_data(message)
      else
        @log_out.info("Unexpected error: #{error}")
      end
    end
  end

  def require_private_chat(bot, message)
    if message.chat.type != 'private'
      reply(bot, message, 'Nu, me da vergüenza (ꈍ▽ꈍ) Háblame en privado.')
      return false
    end
    return true
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
      when '403' # Blocked
        @user_info_handler.clear_data(message)
      else
        @log_out.info("Unexpected error: #{error}")
      end
    end
  end
end

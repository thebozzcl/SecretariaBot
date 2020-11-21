require 'zache'

class UserInfoHandler
  def initialize(user_info, chat_info)
    @user_info = user_info
    @chat_info = chat_info
    @chat_name_cache = Zache.new
    @chat_name_cache_expiration = 3600
  end

  def register_user(message)
    user_name = get_username(message)
    @chat_info.add_chat_member(message.chat.type, message.from.id, message.chat.id)
    @user_info.register_user_info(message.from.id, user_name)
  end

  def get_user_groups(bot, message)
    chat_ids = @chat_info.get_known_chats_for_user(message.from.id)
    return 'No me has hablado en ningún grupo :(' if chat_ids.empty?

    chat_names = chat_ids.map do |chat_id|
      get_chat_name(bot, chat_id)
    end.to_a
    chat_names_string = chat_names.join("\n• ")

    "Tus grupos son:\n• #{chat_names_string}"
  end

  def get_user_timezone(message)
    user_info = @user_info.get_user_info(message.from.id)
    return "Dile a @TheBozzUS 'Bozzolo, no funciona'" if user_info.nil?
    timezone = user_info[:timezone]
    if timezone != nil
      "Tu zona horaria es #{timezone}."
    else
      'No me has dicho dónde estás :('
    end
  end

  def clear_data(message)
    @user_info.remove_user_info(message.from.id)
    @chat_info.remove_user_info(message.from.id)
    "#{message.from.first_name}, rompiste mi corazoncito :'("
  end

  def get_username(message)
    if message.from.username != nil
      message.from.username
    elsif message.from.first_name != nil
      message.from.first_name
    elsif message.from.last_name != nil
      message.from.last_name
    else
      'El Usuario Sin Nombre (Bozzolo, no funciona)'
    end
  end

  def get_chat_name(bot, chat_id)
    @chat_name_cache.get(chat_id, lifetime:  @chat_name_cache_expiration) do
      chat = bot.api.get_chat(chat_id: chat_id)
      return chat.nil? ? 'Desconocido' : chat['result']['title']
    end
  end
end

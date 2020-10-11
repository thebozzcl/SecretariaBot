require 'zache'

class ChatInfo

  def initialize (db)
    db.create_table? :chat_members do
      String :chat_id, unique: false, null: false
      String :from_id, unique: false, null: false
      primary_key [:chat_id, :from_id], name: :id
    end
    @chat_members = db[:chat_members]
    @chat_name_cache = Zache.new
    @chat_name_cache_expiration = 3600
  end

  def add_chat_member (chat_type, from_id, chat_id)
    if chat_type == "private"
      return
    end
    @chat_members.insert_conflict(:replace).insert(
      :chat_id => chat_id,
      :from_id => from_id
    )
  end

  def remove_user_info (from_id)
    @chat_members.where(
      :from_id => from_id
    ).delete
  end

  def get_known_chat_members (chat_id)
    @chat_members.where(:chat_id => chat_id).map(:from_id)
  end

  def get_known_chats_for_user (from_id)
    @chat_members.where(:from_id => from_id).map(:chat_id)
  end

  def get_chat_name (bot, chat_id)
    @chat_name_cache.get(chat_id, lifetime:  @chat_name_cache_expiration) do
      chat = bot.api.get_chat(chat_id: chat_id)
      return chat == nil ? "Desconocido" : chat['result']['title']
    end
  end
end
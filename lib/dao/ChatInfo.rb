class ChatInfo

  def initialize (db)
    db.create_table? :chat_members do
      String :chat_id, unique: false, null: false
      String :from_id, unique: false, null: false
      primary_key [:chat_id, :from_id], name: :id
    end
    @chat_members = db[:chat_members]
  end

  def add_chat_member (chat_type, from_id, chat_id)
    return if chat_type == 'private'

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
end
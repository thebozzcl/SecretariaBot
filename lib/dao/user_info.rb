class UserInfo
  def initialize (db)
    db.create_table? :user_info do
      String :from_id, unique: false, null: false
      String :from_name, unique: false, null: false
      String :timezone, unique: false, null: true
      primary_key [:from_id], name: :id
    end
    @user_info = db[:user_info]
  end

  def register_user_info (from_id, from_name)
    @user_info.insert_conflict({}).insert(
      :from_id => from_id,
      :from_name => from_name
    )
  end

  def register_user_timezone (from_id, from_name, timezone)
    @user_info.insert_conflict(:replace).insert(
      :from_id => from_id,
      :from_name => from_name,
      :timezone => timezone
    )
  end

  def remove_user_info (from_id)
    @user_info.where(:from_id => from_id).delete
  end

  def get_user_info (from_id)
    @user_info.where(:from_id => from_id)
  end

  def get_users_info (*from_ids)
    @user_info.where([:id, from_ids])
  end
end
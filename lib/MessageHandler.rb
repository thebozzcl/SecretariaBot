class MessageHandler
  def initialize
    @bubble_start = 'く'
    @bubble_end = '❩'
  end

  def get_happy
    [
      '(╹◡╹)', '٩(｡◕‿◕)۶', 'ヽ(o＾▽＾o)ノ', '╰(▔∀▔)╯', '( ‾́ ◡ ‾́ )', '(⌒‿⌒)'
    ].sample
  end

  def get_sad
    [
      '(ಥ﹏ಥ)', '(T⌓T)', '(╥﹏╥)', '(ಠ ∩ಠ)', '(ó﹏ò｡)', '(●´^｀●)', '(눈_눈)', '(இ﹏இ`｡)'
    ].sample
  end

  def get_bashful
    [
      '(ꈍ▽ꈍ)', '(*≖ᴗ≖*)', '(*´∀`*)', '(*≧∀≦*)', '(„ಡωಡ„)', '(⁄ ⁄>⁄▽⁄<⁄ ⁄)', '(ﾉ≧ڡ≦)', '(⁄ ⁄•⁄ω⁄•⁄ ⁄)'
    ].sample
  end

  def get_confused
    [
      '(ఠ ͟ ಠ)', '(⋟﹏⋞)', '(⊙_☉)', '（；・д・）', '┐(‘～`;)┌', '（；^ω^）', '┐(´д`)┌'
    ].sample
  end

  def render_happy_message(message, post_message = nil)
    render_message(get_happy, message, post_message)
  end

  def render_sad_message(message, post_message = nil)
    render_message(get_sad, message, post_message)
  end

  def render_bashful_message(message, post_message = nil)
    render_message(get_bashful, message, post_message)
  end

  def render_confused_message(message, post_message = nil)
    render_message(get_confused, message, post_message)
  end

  def render_message(mood, message, post_message = nil)
    bubble_message = "#{mood} #{@bubble_start} #{message} #{@bubble_end}"
    if post_message.nil?
      bubble_message
    end
    "#{bubble_message}\n#{post_message}"
  end
end
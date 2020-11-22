class DateKey
  def initialize(date_str, hour)
    @date_str = date_str
    @hour = hour
  end

  attr_reader :date_str, :hour

  def ==(other)
    date_str == other.date_str && hour == other.hour
  end

  def eql?(other)
    self == other
  end

  def hash
    date_str.hash
  end
end

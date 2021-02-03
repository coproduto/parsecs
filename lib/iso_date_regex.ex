defmodule Parsecs.IsoDateRegex do
  # Formato de mês ISO: YYYY-MM
  # Formato de data ISO: YYYY-MM-DD
  # Formato de data e tempo ISO: YYYY-MM-DDTHH:MM:SSZ
  
  def is_year(string) do
    String.match?(string, ~r/\d{4}/)
  end

  def is_month(string) do
    String.match?(string, ~r/\d{2}/)
  end

  def is_day(string) do
    String.match?(string, ~r/\d{2}/)
  end

  def is_iso_month_of_year(string) do
    String.match?(string, ~r/\d{4}-\d{2}/)
  end

  def is_iso_date(string) do
    String.match?(string, ~r/\d{4}-\d{2}-\d{2}/)
  end

  def parse_iso_date(string) do
    case Regex.run(~r/(\d{4})-(\d{2})-(\d{2})/, string) do
      [year, month, day] -> {:ok, Date.new(year, month, day)}
      _ -> {:error, :invalid_format}
    end
  end

  def parse_iso_utc_datetime(string) do
    case Regex.run(~r/(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z/, string) do
      [_, year, month, day, hour, minute, second] ->
	{:ok,
	 DateTime.new!(
	   Date.new!(String.to_integer(year), String.to_integer(month), String.to_integer(day)),
	   Time.new!(String.to_integer(hour), String.to_integer(minute), String.to_integer(second))
	 )
	}
      _ -> {:error, :invalid_format}
    end
  end
end

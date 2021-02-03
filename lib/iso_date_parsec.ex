defmodule Parsecs.IsoDateParsec do
  import NimbleParsec

  year = integer(4)

  month = integer(2)

  day = integer(2)

  defparsec :month_of_year,
    year
    |> ignore(string("-"))
    |> concat(month)

  defparsec :iso_date,
    parsec(:month_of_year)
    |> ignore(string("-"))
    |> concat(day)

  hour = integer(2)

  minute = integer(2)

  second = integer(2)

  time =
    hour
    |> ignore(string(":"))
    |> concat(minute)
    |> ignore(string(":"))

  defparsec :iso_datetime,
    parsec(:iso_date)
    |> ignore(string("T"))
    |> concat(time)
end

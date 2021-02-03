defmodule Parsecs.CustomParsec do
  # Parser Combinator: (params) -> ((string) -> ({:ok, data, resto} | {:error, err}))
  # fn x -> ... end
  def char(c) do
    fn
      <<^c::utf8>> <> rest -> {:ok, <<c::utf8>>, rest}
      _ -> {:error, "Expected #{<<c::utf8>>}"}
    end
  end

  def string("") do
    fn str -> {:ok, "", str} end
  end

  def string(<<c::utf8>> <> rest) do
    fn str ->
      case pair(char(c), string(rest)).(str) do
	{:ok, {first, str}, rest} -> {:ok, first <> str, rest}
	{:error, err} -> {:error, err}
      end
    end
  end

  def pair(c1, c2) do
    fn str ->
      case c1.(str) do
	{:ok, r1, first_rest} ->
	  case c2.(first_rest) do
	    {:ok, r2, second_rest} ->
	      {:ok, {r1, r2}, second_rest}

	    {:error, err} -> {:error, err}
	  end

	{:error, err} -> {:error, err}
      end
    end
  end

  def digit() do
    fn
      <<c::utf8>> <> rest when c in ?0..?9 ->
	{:ok, c - ?0, rest}
      _ -> {:error, "Expected digit"}
    end
  end

  def integer(0) do
    fn str -> {:ok, 0, str} end
  end

  def integer(n) do
    fn str ->
      case pair(digit(), integer(n-1)).(str) do
        {:ok, {a, b}, rest} ->
	  power = :math.pow(10, n-1) |> round
	  {:ok, power * a + b, rest}
	{:error, err} ->
	  {:error, err}
      end
    end
  end

  def list([]), do: fn str -> {:ok, [], str} end

  def list([p | ps]) do
    fn str ->
      case p.(str) do
	{:ok, head_result, head_rest} ->
	  case list(ps).(head_rest) do
	    {:ok, tail_result, tail_rest} -> {:ok, [head_result | tail_result], tail_rest}
	    {:error, err} -> {:error, err}
	  end

	{:error, err} -> {:error, err}
      end
    end
  end

  def ignore(parsec) do
    fn str ->
      case parsec.(str) do
	{:ok, r, rest} -> {:ok, {:ignore, r}, rest}
	{:error, err} -> {:error, err}
      end
    end
  end

  defp clean_result([]), do: []

  defp clean_result([{:ignore, _} | rest]), do: clean_result(rest)

  defp clean_result([value | rest]), do: [value | clean_result(rest)]

  def parse(parsec, str) do
    case parsec.(str) do
      {:ok, l, rest} when is_list(l) -> {:ok, clean_result(l), rest}
      {:ok, {:ignore, _}, rest} -> {:ok, nil, rest}
      {:ok, r, rest} -> {:ok, r, rest}
      {:error, err} -> {:error, err}
    end
  end

  def datetime() do
    list [
      integer(4),
      ignore(string("-")),
      integer(2),
      ignore(string("-")),
      integer(2),
      ignore(string("T")),
      integer(2),
      ignore(string(":")),
      integer(2),
      ignore(string(":")),
      integer(2),
      ignore(string("Z"))
    ]
  end

  def parsec_apply(parsec, f) do
    fn str ->
      case parsec.(str) do
	{:ok, result, rest} -> {:ok, f.(clean_result(result)), rest}
	{:error, err} -> {:error, err}
      end
    end
  end

  def datetime_2() do
    datetime() |> parsec_apply(fn
      [year, month, day, hour, min, sec] ->
	DateTime.new!(
	  Date.new!(year, month, day),
	  Time.new!(hour, min, sec)
	)
    end)
  end
end

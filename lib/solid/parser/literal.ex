defmodule Solid.Parser.Literal do
  import NimbleParsec

  @dialyzer :no_opaque

  def minus, do: string("-")
  def plus, do: string("+")

  def whitespace(opts) do
    utf8_string([?\s, ?\n, ?\r, ?\t], opts)
  end

  def int do
    optional(minus())
    |> concat(integer(min: 1))
    |> reduce({Enum, :join, [""]})
    |> map({String, :to_integer, []})
  end

  def single_quoted_string do
    ignore(string(~s(')))
    |> repeat(
      lookahead_not(ascii_char([?']))
      |> choice([string(~s(\')), utf8_char([])])
    )
    |> ignore(string(~s(')))
    |> reduce({List, :to_string, []})
  end

  def double_quoted_string do
    ignore(string(~s(")))
    |> repeat(
      lookahead_not(ascii_char([?"]))
      |> choice([string(~s(\")), utf8_char([])])
    )
    |> ignore(string(~s(")))
    |> reduce({List, :to_string, []})
  end

  def value do
    frac =
      string(".")
      |> concat(integer(min: 1))

    exp =
      choice([string("e"), string("E")])
      |> optional(choice([plus(), minus()]))
      |> integer(min: 1)

    float =
      int()
      |> concat(frac)
      |> optional(exp)
      |> reduce({Enum, :join, [""]})
      |> map({String, :to_float, []})

    choice([
      float,
      int(),
      single_quoted_string(),
      double_quoted_string()
    ])
    |> unwrap_and_tag(:value)
  end
end

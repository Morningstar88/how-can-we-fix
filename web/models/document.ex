defmodule AlchemyBook.Document do
  use AlchemyBook.Web, :model

  @crdt_base 256
  @default_site 0

  schema "documents" do
    field :title, :string
    field :contents, :string
    belongs_to :user, AlchemyBook.User

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :contents])
    #|> validate_required([:title, :contents])
  end

  def default() do
    %{ "title" => "untitled", 
       "contents" => crdt_to_json(string_to_crdt("Time to do some alchemy!"))
    }
  end

  def json_to_crdt(json) do
    json
    |> Poison.decode!
    |> Enum.map(fn [position_identifier, char] ->
      {Enum.map(position_identifier, fn [pos, site] -> {pos, site} end), char}
    end)
  end

  def crdt_to_json(crdt) do 
    crdt_to_json_ready(crdt)
    |> Poison.encode!
  end

  def crdt_to_json_ready(crdt) do 
    crdt
    |> Enum.concat
    |> Enum.map(fn {position_identifier, char} ->
      [Enum.map(position_identifier, fn {pos, site} -> [pos, site] end), char]
    end)
  end

  defp string_to_crdt(string) do
    # TODO: support for bigger strings
    # (right now this is used only for the default string)
    if String.length(string) >= @crdt_base do
      throw "no supported yet"
    end

    string
    |> String.to_charlist
    |> Enum.with_index
    |> Enum.map(fn {char, index} ->
      identifier = { trunc(index / String.length(string) * @crdt_base), @default_site }
      { [identifier], to_string([char]) }
    end)
  end

  # TODO: probably not needed on the server side?
  defp _split_by_newline(crdt_charlist) do
    IO.puts inspect crdt_charlist
    case Enum.find_index(crdt_charlist, fn {_, char} -> char == "\n" end) do
      nil ->
        [crdt_charlist]
      index ->
        {line, rest} = Enum.split(crdt_charlist, index + 1)
        [line | split_by_newline(rest)]
    end
  end
end
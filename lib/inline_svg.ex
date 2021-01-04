defmodule InlineSvg do
  @moduledoc """
  Documentation for `InlineSvg`.
  """

  require Logger

  defmodule Error do
    @moduledoc false
    defexception message: nil, svg: nil
  end


  #--------------------------------------------------------
  def compile( %{} = library \\ %{}, svg_root  ) when is_bitstring(svg_root) do
    svg_root
    |> Kernel.<>( "/**/*.svg" )
    |> Path.wildcard()
    |> Enum.reduce( library, fn(path, acc) ->
      with {:ok, key, svg} <- read_svg( path, svg_root ),
      :ok <- unique_key( library, key, path ) do
        Map.put( acc, key, svg <> "</svg>" )
      else
        {:file_error, err, path} ->
          raise %Error{message: "SVG file #{inspect(path)} is invalid, err: #{err}", svg: path}
        {:duplicate, key, path} ->
          Logger.warn("SVG file: #{path} overwrites existing svg: #{key}")
      end
    end)
  end

  defp read_svg( path, root ) do
    with {:ok, svg} <- File.read( path ),
    true <- String.valid?(svg),
    [_,svg] <- String.split(svg, "<svg"),
    [svg,_] <- String.split(svg, "</svg>") do
      { 
        :ok,
        path # make the key
        |> String.trim(root)
        |> String.trim("/")
        |> String.trim_trailing(".svg"),
        svg
      }
    else
      err -> {:file_error, err, path}
    end
  end

  defp unique_key(library, key, path) do
    case Map.fetch( library, key ) do
      {:ok, _} -> {:duplicate, key, path}
      _ -> :ok
    end
  end


  #--------------------------------------------------------
  def render( %{} = library, key, attrs \\ [] ) do
    case Map.fetch( library, key ) do
      {:ok, svg} -> {:safe, "<svg" <> render_attrs(attrs) <> svg}
      _ -> raise %Error{message: "SVG #{inspect(key)} not found", svg: key}
    end
  end

  #--------------------------------------------------------
  # transform an opts list into a string of tag options
  def render_attrs( attrs ), do: do_render_attrs( attrs, "" )
  defp do_render_attrs( [], acc ), do: acc
  defp do_render_attrs( [{key,value} | tail ], acc ) do
    key = to_string(key) |> String.replace("_", "-")
    do_render_attrs( tail, "#{acc} #{key}=#{inspect(value)}" )
  end
  
end

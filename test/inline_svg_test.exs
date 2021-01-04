defmodule InlineSvgTest do
  use ExUnit.Case
  doctest InlineSvg

  import ExUnit.CaptureLog
  require Logger

  # build the svg library at compile time
  @svg_library InlineSvg.compile("test/svgs")

  def library(), do: @svg_library

  #--------------------------------------------------------
  # compile

  test "compile traversed the tree, built nested paths, and stripped the .svg from the name" do
    assert Map.get(library(), "x")
    assert Map.get(library(), "nested/list")
    assert Map.get(library(), "more/cube")
  end

  test "compile can be piped into multiple folders" do
    library = InlineSvg.compile("test/svgs/more")
    |> InlineSvg.compile("test/svgs/nested")

    refute Map.get(library, "x")
    assert Map.get(library, "list")
    assert Map.get(library, "cube")
  end

  test "compile logs a warning when overwriting an existing svg file" do
    log = capture_log(fn->
      InlineSvg.compile("test/svgs/more")
      |> InlineSvg.compile("test/svgs/more")
    end)
    assert log =~ "[warn]  SVG file:"
    assert log =~ "overwrites existing svg: cube"
  end

  test "compile raises an error when reading an invalid svg file" do
    assert_raise InlineSvg.Error, fn ->
      InlineSvg.compile("test/svg_invalid")
    end
  end

  #--------------------------------------------------------
  # render

  test "render retrieves the svg as a safe string" do
    {:safe, svg} = InlineSvg.render( library(), "x" )
    assert String.starts_with?( svg, "<svg xmlns=" )
  end

  test "render inserts optional attributes" do
    {:safe, svg} = InlineSvg.render( library(), "x", class: "test_class", "@click": "action" )
    assert String.starts_with?( svg, "<svg class=\"test_class\" @click=\"action\" xmlns=" )
  end

  test "render raises an error if the svg is not in the library" do
    assert_raise InlineSvg.Error, fn ->
      InlineSvg.render( library(), "missing" )
    end
  end

  #--------------------------------------------------------
  # render_attrs

  test "render_attrs returns an empty string if opts is empty" do
    assert InlineSvg.render_attrs([]) == ""
  end

  test "render_attrs returns an empty string with the rendered attributes" do
    assert InlineSvg.render_attrs(abc: 123, def: "test attr") == " abc=123 def=\"test attr\""
  end

  test "render_attrs converts the _ character into - in keys" do
    assert InlineSvg.render_attrs(abc_def: 123, def: "test_attr") == " abc-def=123 def=\"test_attr\""
  end

end

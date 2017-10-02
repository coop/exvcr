defmodule ExVCR.Tags do
  @moduledoc """
  This module defines a tag to remove the boilerplate of using ExVCR.

  ## Example:

      defmodule Foo.Bar do
        @tag :vcr
        test "my wonderful test" do
          # the recording will be stored in "Foo.Bar/my_wonderful_test.json"
        end
      end

  All the options you'd usually pass to `use_cassette` can be passed to @tag:

      defmodule Foo.Bar do
        @tag vcr: [match_requests_on: [:query]]
        test "my wonderful test" do
        end
      end
  """

  defmacro __using__(_opts) do
    quote do
      setup context do
        setup_vcr(context)

        :ok
      end

      defp setup_vcr(%{vcr: opts} = context) when is_list(opts) do
        describe_name = context[:describe] || ""
        test_name =
          context.test
          |> to_string()
          |> String.replace("test #{describe_name} ", "")
        fixture =
          [to_string(__MODULE__), describe_name, test_name]
          |> Enum.map(&normalize_fixture(&1))
          |> Enum.join("/")

        opts = opts ++ [fixture: fixture, adapter: ExVCR.Adapter.IBrowse]
        recorder = ExVCR.Recorder.start(opts)

        ExVCR.Mock.mock_methods(recorder, ExVCR.Adapter.IBrowse)

        on_exit fn ->
          ExVCR.Recorder.save(recorder)
        end

        :ok
      end
      defp setup_vcr(%{vcr: true} = context), do: setup_vcr(Map.put(context, :vcr, []))
      defp setup_vcr(_), do: :ok

      defp normalize_fixture(fixture) do
        fixture
        |> String.replace(~r/\s/, "_")
        |> String.replace("/", "-")
        |> String.replace(",", "")
        |> String.replace("'", "")
        |> String.replace("`", "")
        |> String.replace("Elixir.", "")
      end
    end
  end
end

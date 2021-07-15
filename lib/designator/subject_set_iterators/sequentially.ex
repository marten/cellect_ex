defmodule Designator.SubjectSetIterators.Sequentially do
  @spec apply_to(Enumerable.t) :: Enumerable.t
  def apply_to(enum) do
    Stream.with_index(enum) |> Stream.map(fn {elem,index} -> {index, elem} end)
  end

  defp size(enum = %Array{}) do
    Array.size(enum)
  end

  defp size(enum) do
    Enum.count(enum)
  end
end

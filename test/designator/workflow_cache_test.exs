defmodule Designator.WorkflowCacheTest do
  use Designator.ConnCase
  use Designator.CacheCase

  describe "reloading" do
    test "reloads configuration" do
      {:ok, workflow} = Workflow.changeset(%Workflow{}, %{configuration: %{a: 1}}) |> Repo.insert
      assert WorkflowCache.get(workflow.id).configuration == %{"a" => 1}

      {:ok, _} = Workflow.changeset(workflow, %{configuration: %{a: 2}}) |> Repo.update
      assert WorkflowCache.get(workflow.id).configuration == %{"a" => 1}

      WorkflowCache.reload(workflow.id)
      assert WorkflowCache.get(workflow.id).configuration == %{"a" => 2}
    end
  end

  test "default configuration" do
    workflow_id_not_in_db = 2
    assert WorkflowCache.get(workflow_id_not_in_db) == %Designator.WorkflowCache{
      configuration: %{},
      id: 2,
      prioritized: false,
      subject_set_ids: []
    }
  end
end

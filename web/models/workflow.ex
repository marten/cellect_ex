defmodule Designator.Workflow do
  use Ecto.Schema
  import Ecto.Query, only: [from: 2]

  use Designator.Web, :model

  schema "workflows" do
    field :project_id, :integer
    field :configuration, :map
    field :prioritized, :boolean

    timestamps inserted_at: :created_at
  end

  def find(workflow_id) do
    __MODULE__ |> Designator.Repo.get(workflow_id)
  end

  def subject_set_ids(workflow_id) do
    query = from ssw in "subject_sets_workflows",
      where: ssw.workflow_id == ^workflow_id,
      select: ssw.subject_set_id

    Designator.Repo.all(query)
  end

  def subject_ids(workflow_id, subject_set_id) do
    query = from sms in "set_member_subjects",
      left_join: swc in "subject_workflow_counts", on: (sms.subject_id == swc.subject_id and swc.workflow_id == ^workflow_id),
      where: sms.subject_set_id == ^subject_set_id and is_nil(swc.retired_at),
      select: {sms.subject_id, sms.priority}
    Designator.Repo.all(query)
    |> List.keysort(1)
    |> Enum.map(fn {k, _v} -> k end)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:id, :configuration])
  end

end

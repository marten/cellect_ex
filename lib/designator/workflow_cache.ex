defmodule Designator.WorkflowCache do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      supervisor(ConCache, [[ttl_check: :timer.seconds(5),
                             ttl: :timer.minutes(15),
                             touch_on_read: false],
                            [name: :workflow_cache]]),
    ]

    supervise(children, strategy: :one_for_one)
  end

  ### Public API

  defstruct [:id, :subject_set_ids, :configuration, :prioritized]

  def status do
    :workflow_cache
    |> ConCache.ets
    |> :ets.tab2list
    |> Enum.map(fn({_, val}) ->
      %{workflow_id: val.id,
        subject_set_ids: val.subject_set_ids,
        configuration: val.configuration}
    end)
  end

  def get(workflow_id) do
    ConCache.get_or_store(:workflow_cache, workflow_id, fn() ->
      fetch_workflow(workflow_id)
    end)
  end

  def set(workflow_id, workflow) do
    ConCache.update(:workflow_cache, workflow_id, fn(old_workflow) ->
      case old_workflow do
        nil ->
          {:ok , Map.merge(%__MODULE__{id: workflow_id}, workflow)}
        w ->
          {:ok, Map.merge(w, workflow)}
      end
    end)
  end

  def reload(workflow_id) do
    ConCache.update(:workflow_cache, workflow_id, fn(_old_workflow) ->
      {:ok, fetch_workflow(workflow_id)}
    end)
  end

  defp fetch_workflow(workflow_id) do
    case Designator.Workflow.find(workflow_id) do
      nil ->
        %__MODULE__{
          id: workflow_id,
          subject_set_ids: [],
          configuration: %{},
          prioritized: false
        }
      workflow ->
        %__MODULE__{
          id: workflow_id,
          subject_set_ids: Designator.Workflow.subject_set_ids(workflow_id),
          configuration: workflow.configuration,
          prioritized: workflow.prioritized
       }
    end
  end
end

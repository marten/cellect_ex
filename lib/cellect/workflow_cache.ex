defmodule Cellect.WorkflowCache do
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

  defstruct [:id, :subject_set_ids, :configuration]

  def get(workflow_id) do
    ConCache.get_or_store(:workflow_cache, workflow_id, fn() ->
      case Cellect.Workflow.find(workflow_id) do
        nil ->
          %__MODULE__{
            id: workflow_id,
            subject_set_ids: [],
            configuration: %{}
          }
        workflow ->
          %__MODULE__{
            id: workflow_id,
            subject_set_ids: Cellect.Workflow.subject_set_ids(workflow_id),
            configuration: workflow.configuration
          }
      end
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
end

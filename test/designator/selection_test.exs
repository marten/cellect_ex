defmodule Designator.SelectionTest do
  use Designator.ConnCase
  use Designator.CacheCase
  alias Designator.Selection
  alias Designator.Repo
  alias Designator.UserSeenSubject
  alias Designator.SubjectSetCache

  describe "training set weighting" do
    setup do
      Designator.Random.seed({123, 123534, 345345})
      Designator.WorkflowCache.set(
        338,
        %{
          configuration: %{
            "training_set_ids" => [681, 1706],
            "training_chances" => [0.1, 0.1, 0.1, 0.1, 0.9]},
            subject_set_ids: [681, 1706, 1682, 1681]
          }
      )

      SubjectSetCache.set({338, 681},  %SubjectSetCache{workflow_id: 338, subject_set_id: 681, subject_ids: Array.from_list([1])})
      SubjectSetCache.set({338, 1706}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1706, subject_ids: Array.from_list([2])})
      SubjectSetCache.set({338, 1682}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1682, subject_ids: Array.from_list(Enum.into(10..19, []))})
      SubjectSetCache.set({338, 1681}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1681, subject_ids: Array.from_list(Enum.into(20..29, []))})
    end

    test "logged in users" do
      Designator.UserCache.set({338, 1}, %{seen_ids: MapSet.new([5,6,7,8]),
                                          recently_selected_ids: MapSet.new,
                                          configuration: %{}})
      assert Selection.select(338, 1, [limit: 202]) == [2, 1, 15, 13, 27, 18, 16, 25, 17, 24, 19, 20, 22, 10, 12, 11, 14, 21, 29, 28, 26, 23]
    end

    test "non-logged in users" do
      assert Selection.select(338, nil, [limit: 202]) == [29, 24, 21, 20, 15, 13, 18, 27, 12, 19, 16, 10, 17, 11, 14, 23, 25, 22, 26, 28, 2, 1]
    end
  end

  test "gold standard weighting" do
    Designator.Random.seed({123, 123534, 345345})
    Designator.WorkflowCache.set(338, %{configuration: %{"gold_standard_sets" => [681, 1706]},
                                     subject_set_ids: [681, 1706, 1682, 1681]})
    SubjectSetCache.set({338, 681},  %SubjectSetCache{workflow_id: 338, subject_set_id: 681, subject_ids: Array.from_list([1])})
    SubjectSetCache.set({338, 1706}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1706, subject_ids: Array.from_list([2])})
    SubjectSetCache.set({338, 1682}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1682, subject_ids: Array.from_list([3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3])})
    SubjectSetCache.set({338, 1681}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1681, subject_ids: Array.from_list([4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4])})

    assert Selection.select(338, 1, [limit: 4]) == [4, 2, 1, 3]
  end

  test "spacewarps weighting" do
    Designator.Random.seed({123, 123534, 345345})
    Designator.WorkflowCache.set(338, %{configuration: %{"spacewarps_training_sets" => [681, 1706]},
                                     subject_set_ids: [681, 1706, 1682, 1681]})
    SubjectSetCache.set({338, 681},  %SubjectSetCache{workflow_id: 338, subject_set_id: 681, subject_ids: Array.from_list([1])})
    SubjectSetCache.set({338, 1706}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1706, subject_ids: Array.from_list([2])})
    SubjectSetCache.set({338, 1682}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1682, subject_ids: Array.from_list([3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3])})
    SubjectSetCache.set({338, 1681}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1681, subject_ids: Array.from_list([4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4])})

    assert Selection.select(338, 1, [limit: 4]) == [4, 2, 3, 1]
  end

  test "sequential selection for normal sets" do
    Designator.Random.seed({123, 100020, 345345})
    Designator.WorkflowCache.set(338, %{configuration: %{}, prioritized: true, subject_set_ids: [1000]})
    Designator.UserCache.set({338, 1}, %{seen_ids: MapSet.new, recently_selected_ids: MapSet.new, configuration: %{}})
    SubjectSetCache.set({338, 1000}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1000, subject_ids: Array.from_list([98, 99, 10])})

    assert Selection.select(338, 1, [limit: 6]) == [98, 99, 10]
  end

  test "weighed selection for normal sets" do
    Designator.Random.seed({123, 100020, 345345})
    Designator.WorkflowCache.set(338, %{configuration: %{"subject_set_weights" => %{"1000" => 1, "1001" => 99, "1002" => 9.9, "1003" => 0.1}},
                                     subject_set_ids: [1000, 1001, 1002, 1003]})
    Designator.UserCache.set({338, 1}, %{seen_ids: MapSet.new,
                                         recently_selected_ids: MapSet.new,
                                         configuration: %{subject_set_weights: %{"1000" => 900}}})
    SubjectSetCache.set({338, 1000}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1000, subject_ids: Array.from_list([1, 2, 3])})
    SubjectSetCache.set({338, 1001}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1001, subject_ids: Array.from_list([4])})
    SubjectSetCache.set({338, 1002}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1002, subject_ids: Array.from_list([5])})
    SubjectSetCache.set({338, 1003}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1003, subject_ids: Array.from_list([6])})

    assert Selection.select(338, 1, [limit: 6]) == [4, 5, 1, 2, 3, 6]
  end

  @tag timeout: 1000
  test "seen all subjects" do
    Designator.Random.seed({123, 123534, 345345})
    Designator.WorkflowCache.set(338, %{configuration: %{"gold_standard_sets" => [681, 1706]},
                                     subject_set_ids: [681, 1706, 1682, 1681]})
    SubjectSetCache.set({338, 681},  %SubjectSetCache{workflow_id: 338, subject_set_id: 1000, subject_ids: Array.from_list([1])})
    SubjectSetCache.set({338, 1706}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1001, subject_ids: Array.from_list([2])})
    SubjectSetCache.set({338, 1682}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1002, subject_ids: Array.from_list([3])})
    SubjectSetCache.set({338, 1681}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1003, subject_ids: Array.from_list([4])})
    Designator.UserSeenSubject.changeset(%UserSeenSubject{}, %{user_id: 1, workflow_id: 338, subject_ids: [1,2,3,4]}) |> Repo.insert!

    assert Designator.UserCache.get({338, 1}).seen_ids == MapSet.new([1,2,3,4])

    assert Selection.select(338, 1) == []
  end

  test "selects subjects from a supplied subject_set_id" do
    Designator.Random.seed({123, 123534, 345345})
    Designator.WorkflowCache.set(338, %{ configuration: %{}, subject_set_ids: [681, 1706]})
    SubjectSetCache.set({338, 681},  %SubjectSetCache{workflow_id: 338, subject_set_id: 681, subject_ids: Array.from_list([1])})
    SubjectSetCache.set({338, 1706}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1706, subject_ids: Array.from_list([2])})

    assert Selection.select(338, 1, [subject_set_id: 681, limit: 2]) == [1]
  end

  test "selects subjects from all subject sets if an unknown subject_set_id" do
    Designator.Random.seed({123, 123534, 345345})
    Designator.WorkflowCache.set(338, %{ configuration: %{}, subject_set_ids: [681, 1706]})
    SubjectSetCache.set({338, 681},  %SubjectSetCache{workflow_id: 338, subject_set_id: 681, subject_ids: Array.from_list([1])})
    SubjectSetCache.set({338, 1706}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1706, subject_ids: Array.from_list([2])})

    assert Selection.select(338, 1, [subject_set_id: 1, limit: 2]) == [2,1]
  end

  test "does not select recently handed out subject ids" do
    Designator.Random.seed({123, 123534, 345345})
    Designator.WorkflowCache.set(338, %{configuration: %{"gold_standard_sets" => [681, 1706]},
                                     subject_set_ids: [681, 1706, 1682, 1681]})
    SubjectSetCache.set({338, 681},  %SubjectSetCache{workflow_id: 338, subject_set_id: 681, subject_ids: Array.from_list([1])})
    SubjectSetCache.set({338, 1706}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1706, subject_ids: Array.from_list([2])})
    SubjectSetCache.set({338, 1682}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1682, subject_ids: Array.from_list([3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3])})
    SubjectSetCache.set({338, 1681}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1681, subject_ids: Array.from_list([4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4])})

    _run_selection_to_setup_cache = Selection.select(338, 1, [limit: 4])
    assert Selection.select(338, 1, [limit: 4]) == []
  end

  test "does not select recently retired subject ids" do
    Designator.Random.seed({123, 123534, 345345})
    Designator.WorkflowCache.set(338, %{configuration: %{"gold_standard_sets" => [681, 1706]},
                                        subject_set_ids: [681]})
    SubjectSetCache.set({338, 681},  %SubjectSetCache{workflow_id: 338, subject_set_id: 681, subject_ids: Array.from_list([1, 2, 3, 4])})
    Designator.RecentlyRetired.add(338, 1)
    Designator.RecentlyRetired.add(338, 2)
    Designator.RecentlyRetired.add(338, 3)

    assert Selection.select(338, 1, [limit: 4]) == [4]
  end

  test "workflow that does not exist" do
    assert Selection.select(404, 1) == []
  end

  test "empty subject set" do
    Designator.Random.seed({123, 123534, 345345})
    Designator.WorkflowCache.set(338, %{configuration: %{"gold_standard_sets" => [681, 1706]},
                                     subject_set_ids: [681, 1706, 1682, 1681]})
    SubjectSetCache.set({338, 681}, %SubjectSetCache{workflow_id: 338, subject_set_id: 1000, subject_ids: Array.from_list([])})
    SubjectSetCache.set({338, 1706},%SubjectSetCache{workflow_id: 338, subject_set_id: 1001, subject_ids: Array.from_list([])})
    SubjectSetCache.set({338, 1682},%SubjectSetCache{workflow_id: 338, subject_set_id: 1002, subject_ids: Array.from_list([3])})
    SubjectSetCache.set({338, 1681},%SubjectSetCache{workflow_id: 338, subject_set_id: 1003, subject_ids: Array.from_list([4])})

    assert Selection.select(338, 1, [limit: 2]) == [4, 3]
  end
end

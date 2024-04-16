defmodule AsyncTaskDemoWeb.TaskControllerTest do
  use AsyncTaskDemoWeb.ConnCase, async: true

  describe "create/2" do
    test "creates task successfully with high priority", %{conn: conn} do
      payload =
        Jason.encode!(%{
          max_attempts: 10,
          type: "finances",
          priority: "high",
          data: %{
            generate: "report",
            timeline: "quoter",
            sort: "credit"
          }
        })

      assert %{
               "max_attempts" => 10,
               "data" => %{
                 "generate" => "report",
                 "sort" => "credit",
                 "timeline" => "quoter"
               },
               "id" => id,
               "priority" => "high",
               "type" => "finances",
               "state" => "new",
               "updated_at" => updated_at,
               "inserted_at" => inserted_at
             } =
               conn
               |> post(~p"/api/users", payload)
               |> json_response(201)

      assert id
      assert inserted_at
      assert updated_at
    end

    test "creates task successfully with normal priority", %{conn: conn} do
      payload =
        Jason.encode!(%{
          type: "images",
          priority: "normal",
          data: %{
            command: "qpdf",
            args: "--deterministic-id",
            files: ["1.pdf", "2.pdf"]
          }
        })

      assert %{
               "data" => %{
                 "args" => "--deterministic-id",
                 "command" => "qpdf",
                 "files" => ["1.pdf", "2.pdf"]
               },
               "id" => id,
               "inserted_at" => inserted_at,
               "priority" => "normal",
               "type" => "images",
               "max_attempts" => 5,
               "state" => "new",
               "updated_at" => updated_at
             } =
               conn
               |> post(~p"/api/users", payload)
               |> json_response(201)

      assert id
      assert inserted_at
      assert updated_at
    end

    test "creates task successfully with normal priority by default", %{conn: conn} do
      payload =
        Jason.encode!(%{
          type: "images",
          data: %{
            command: "qpdf",
            args: "--deterministic-id",
            files: ["1.pdf", "2.pdf"]
          }
        })

      assert %{
               "data" => %{
                 "args" => "--deterministic-id",
                 "command" => "qpdf",
                 "files" => ["1.pdf", "2.pdf"]
               },
               "id" => id,
               "inserted_at" => inserted_at,
               "priority" => "normal",
               "type" => "images",
               "max_attempts" => 5,
               "state" => "new",
               "updated_at" => updated_at
             } =
               conn
               |> post(~p"/api/users", payload)
               |> json_response(201)

      assert id
      assert inserted_at
      assert updated_at
    end

    test "creates task successfully with low priority", %{conn: conn} do
      payload =
        Jason.encode!(%{
          type: "student_homework",
          priority: "low",
          data: %{
            kind: "reverse_polish_notation_check",
            expression: "expression (3 + 4) * (5 + 6)",
            expectation: "3 4 + 5 6 + *"
          }
        })

      assert %{
               "data" => %{
                 "expectation" => "3 4 + 5 6 + *",
                 "expression" => "expression (3 + 4) * (5 + 6)",
                 "kind" => "reverse_polish_notation_check"
               },
               "id" => id,
               "inserted_at" => inserted_at,
               "priority" => "low",
               "type" => "student_homework",
               "max_attempts" => 5,
               "state" => "new",
               "updated_at" => updated_at
             } =
               conn
               |> post(~p"/api/users", payload)
               |> json_response(201)

      assert id
      assert inserted_at
      assert updated_at
    end

    test "returns propper error for max_attempts < 0", %{conn: conn} do
      payload =
        Jason.encode!(%{
          type: "student_homework",
          priority: "low",
          data: %{},
          max_attempts: -1
        })

      assert %{
               "errors" => [
                 %{
                   "message" => "-1 is smaller than inclusive minimum 0",
                   "source" => %{"pointer" => "/max_attempts"},
                   "title" => "Invalid value"
                 }
               ]
             } =
               conn
               |> post(~p"/api/users", payload)
               |> json_response(422)
    end

    test "returns propper error when type is not defined", %{conn: conn} do
      assert %{
               "errors" => [
                 %{
                   "message" => "Missing field: type",
                   "source" => %{"pointer" => "/type"},
                   "title" => "Invalid value"
                 }
               ]
             } =
               conn
               |> post(~p"/api/users", Jason.encode!(%{data: %{text: "Hello"}}))
               |> json_response(422)
    end

    test "returns propper error when data is not defined", %{conn: conn} do
      assert %{
               "errors" => [
                 %{
                   "message" => "Missing field: data",
                   "source" => %{"pointer" => "/data"},
                   "title" => "Invalid value"
                 }
               ]
             } =
               conn
               |> post(~p"/api/users", Jason.encode!(%{type: :low}))
               |> json_response(422)
    end

    test "returns propper error when priority value is invalid", %{conn: conn} do
      assert %{
               "errors" => [
                 %{
                   "message" => "Invalid value for enum",
                   "source" => %{"pointer" => "/priority"},
                   "title" => "Invalid value"
                 }
               ]
             } =
               conn
               |> post(
                 ~p"/api/users",
                 Jason.encode!(%{priority: :unknown, type: "finances", data: %{id: 1}})
               )
               |> json_response(422)
    end
  end
end

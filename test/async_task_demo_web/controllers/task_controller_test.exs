defmodule AsyncTaskDemoWeb.TaskControllerTest do
  use AsyncTaskDemoWeb.ConnCase, async: true

  describe "create/2" do
    test "creates task successfully with high priority", %{conn: conn} do
      payload =
        Jason.encode!(%{
          type: "finances",
          priority: "high",
          data: %{
            generate: "report",
            timeline: "quoter",
            sort: "credit"
          }
        })

      assert %{
               "data" => %{
                 "generate" => "report",
                 "sort" => "credit",
                 "timeline" => "quoter"
               },
               "id" => id,
               "inserted_at" => inserted_at,
               "priority" => "high",
               "type" => "finances",
               "updated_at" => updated_at
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
               "updated_at" => updated_at
             } =
               conn
               |> post(~p"/api/users", payload)
               |> json_response(201)

      assert id
      assert inserted_at
      assert updated_at
    end

    test "returns propper error for invalid payload", %{conn: conn} do
      payloads = [
        %{},
        %{type: "1234", priority: :unknown, data: ""},
        %{priority: :unknown, type: "finances", data: %{id: 1}},
        %{type: :low},
        %{data: %{text: "Hello"}}
      ]

      for payload <- payloads do
        conn
        |> post(~p"/api/users", payload)
        |> json_response(422)
      end
    end
  end
end

defmodule CalculatorWeb.CalculatorLive do
  @moduledoc """
   this is dthe module for live Calculator 
  """
  use Phoenix.LiveView
  alias CalculatorWeb.PageView
  @topic "calc"

  def mount(_params, _session, socket) do
    CalculatorWeb.Endpoint.subscribe(@topic)

    {
      :ok,
      assign(
        socket,
        score: 0,
        current_number: "",
        operator: "",
        total: 0
      )
    }
  end

  def render(assigns), do: PageView.render("calc.html", assigns)

  def handle_event("number", %{"number" => number}, socket) do
    # IO.inspect(data)
    current_number = "#{socket.assigns.current_number}#{number}"

    CalculatorWeb.Endpoint.broadcast_from(self(), @topic, "update_calc", %{
      current_number: current_number
    })

    {
      :noreply,
      assign(
        socket,
        current_number: current_number
      )
    }
  end

  def handle_event("operator", %{"operator" => operator}, socket) do
    # IO.inspect(data)

    cond do
      socket.assigns.total == 0 and socket.assigns.score == 0 ->
        CalculatorWeb.Endpoint.broadcast_from(self(), @topic, "update_calc", %{
          current_number: ""
        })

        {
          :noreply,
          assign(
            socket,
            current_number: "",
            score: convert_type(socket.assigns.current_number),
            operator: operator
          )
        }

      socket.assigns.total == 0 and socket.assigns.score != 0 ->
        current_score = socket.assigns.score
        current_number = convert_type(socket.assigns.current_number)
        score = operation(socket.assigns.operator, current_score, current_number)

        CalculatorWeb.Endpoint.broadcast_from(self(), @topic, "update_calc", %{
          current_number: ""
        })

        {
          :noreply,
          assign(
            socket,
            current_number: "",
            score: score,
            operator: operator
          )
        }

      socket.assigns.total != 0 ->
        CalculatorWeb.Endpoint.broadcast_from(self(), @topic, "update_calc", %{
          current_number: ""
        })

        {
          :noreply,
          assign(
            socket,
            current_number: "",
            operator: operator,
            total: 0
          )
        }
    end
  end

  def handle_event("solve", _, socket) do
    current_score = socket.assigns.score
    current_number = convert_type(socket.assigns.current_number)
    score = operation(socket.assigns.operator, current_score, current_number)

    CalculatorWeb.Endpoint.broadcast_from(self(), @topic, "update_calc", %{
      current_number: "#{score}"
    })

    {
      :noreply,
      assign(
        socket,
        current_number: "#{score}",
        score: score,
        total: score
      )
    }
  end

  def handle_event("reset", _, socket) do
    CalculatorWeb.Endpoint.broadcast_from(self(), @topic, "update_calc", %{
      current_number: ""
    })

    {
      :noreply,
      assign(
        socket,
        current_number: "",
        score: 0,
        total: 0
      )
    }
  end

  def handle_event("delete", _, socket) do
    delete = delete(socket.assigns.current_number)

    CalculatorWeb.Endpoint.broadcast_from(self(), @topic, "update_calc", %{current_number: delete})

    {
      :noreply,
      assign(
        socket,
        current_number: delete
      )
    }
  end

  def handle_info(%{topic: @topic, payload: payload}, socket) do
    {
      :noreply,
      assign(
        socket,
        :current_number,
        payload.current_number
      )
    }
  end

  defp delete(number) do
    String.codepoints(number) |> Enum.reverse() |> tl() |> Enum.reverse() |> Enum.join()
  end

  defp convert_type(number) do
    codepoints = String.codepoints(number)

    cond do
      Enum.member?(codepoints, ".") == true -> String.to_float(number)
      Enum.member?(codepoints, ".") == false -> String.to_integer(number)
    end
  end

  defp operation(operator, current_score, current_number) do
    cond do
      operator == "+" -> current_score + current_number
      operator == "-" -> current_score - current_number
      operator == "/" -> current_score / current_number
      operator == "x" -> current_score * current_number
    end
  end
end

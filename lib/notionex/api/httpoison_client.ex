defmodule Notionex.API.HTTPoisonClient do
  @behaviour Notionex.API.Client

  alias Notionex.API.Request

  @impl true
  def request(%Request{} = request, opts \\ %{}) do
    %HTTPoison.Request{
      method: request.method,
      url: request.url,
      body: request.body,
      headers: request.headers,
      params: request.params,
      options: extract_http_options(opts)
    }
    |> do_request()
    |> case do
      {:ok, body} ->
        {:ok, Jason.decode!(body)}

      {:error, error} ->
        {:error, error}
    end
  end

  @impl true
  def request!(%Request{} = request, opts \\ %{}) do
    case request(request, opts) do
      {:ok, response} ->
        response

      {:error, error} ->
        raise error
    end
  end

  defp do_request(%HTTPoison.Request{} = request) do
    case HTTPoison.request(request) do
      {:ok, %{status_code: status_code, body: body}} when status_code in 200..299 ->
        {:ok, body}

      {:ok, %{status_code: status_code} = resp} when status_code >= 400 ->
        {:error, "Client error: #{inspect(resp)}"}

      {:error, resp} ->
        {:error, "HTTPoison error: #{inspect(resp)}"}
    end
  end

  # Extract HTTP-specific options from the opts map and convert to keyword list for HTTPoison
  # HTTPoison supports options like timeout, recv_timeout, connect_timeout, etc.
  defp extract_http_options(opts) when is_map(opts) do
    opts
    |> Map.take([:timeout, :recv_timeout, :connect_timeout, :proxy, :proxy_auth, :ssl, :follow_redirect, :max_redirect, :stream_to, :async, :hackney])
    |> Map.to_list()
  end

  defp extract_http_options(_opts), do: []
end

defmodule KubaWeb.ChatLiveMonitor do
  use GenServer

  def monitor(monitor_pid, live_view_pid, view_module, meta) do
    GenServer.call(monitor_pid, {:monitor, live_view_pid, view_module, meta})
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: ChatLiveMonitor)
  end

  @impl true
  def init(_) do
    {:ok, %{views: %{}}}
  end

  @impl true
  def handle_call({:monitor, pid, view_module, meta}, _, %{views: views} = state) do
    Process.monitor(pid)
    {:reply, :ok, %{state | views: Map.put(views, pid, {view_module, meta})}}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    {{module, meta}, new_views} = Map.pop(state.views, pid)
    module.unmount(meta, reason) # should wrap in isolated task or rescue from exception
    {:noreply, %{state | views: new_views}}
  end
end

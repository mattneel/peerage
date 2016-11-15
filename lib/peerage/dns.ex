defmodule Peerage.Via.Dns do
  @behaviour Peerage.Provider
  require Logger

  @moduledoc """
  Use Dns-based service discovery to find other Nodes.

  ### Example
      config :peerage, via: Peerage.Via.Dns, 
        dns_name: "localhost", 
        app_name: "myapp" 
  
  Will look up the ip(s) for 'localhost', and then try to
  connect to `myapp@$IP`.

  ### Kubernetes

  Kubernetes supports this out of the box for 'headless
  services' -- if you have a service named `myapp`, doing
  `nslookup myapp` in a deployed container will return a 
  list of IP addresses for that service.
  
  More context and resources for using DNS for this:
  - This project's README
  - [SkyDNS announcement](https://blog.gopheracademy.com/skydns/)
  - [Kubernetes DNS for services](http://kubernetes.io/docs/admin/dns/)
  """
  
  def poll, do: lookup |> to_names( [] )

  # erlang dns lookup
  defp lookup,    do: lookup String.to_charlist(hostname)
  defp lookup(c), do: :inet_res.lookup(c,:in,:a)

  # turn list of ips into list of node names
  defp to_names([{a,b,c,d} | rest], acc) when is_list(acc) do
    Logger.debug "  -> Peerage.Via.Dns nslookup result: #{a}.#{b}.#{c}.#{d}"
    to_names rest, [:"#{app_name}@#{a}.#{b}.#{c}.#{d}"] ++ acc
  end
  defp to_names([], lst), do: lst
  defp to_names(err,[]),  do: IO.inspect(["dns err",err]); []

  # get config
  defp app_name do
    Application.get_env(:peerage, :app_name, "nonode")
  end
  defp hostname do
    Application.get_env(:peerage, :dns_name, "localhost")
  end
end
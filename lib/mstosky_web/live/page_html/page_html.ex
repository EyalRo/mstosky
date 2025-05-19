defmodule MstoskyWeb.Live.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageLive (LiveView).

  See the `page_html` directory for all templates available.
  """
  use MstoskyWeb, :html

  embed_templates "page_html/*"
end

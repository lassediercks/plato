defmodule PlatoDemoWeb.PageController do
  use PlatoDemoWeb, :controller

  def home(conn, _params) do
    # Try to fetch CMS content (will be empty until you add it in the admin)
    header = case Plato.get_content("site-header", otp_app: :plato_demo) do
      {:ok, content} -> content
      {:error, _} -> nil
    end

    homepage = case Plato.get_content("homepage", otp_app: :plato_demo) do
      {:ok, content} -> content
      {:error, _} -> nil
    end

    {:ok, blog_posts} = Plato.list_content("blog-post", otp_app: :plato_demo)

    render(conn, :home,
      header: header,
      homepage: homepage,
      blog_posts: blog_posts
    )
  end
end

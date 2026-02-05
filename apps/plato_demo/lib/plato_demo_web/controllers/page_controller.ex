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

  def blog_post(conn, %{"slug" => slug}) do
    case Plato.get_content_by_field("blog-post", "slug", slug, otp_app: :plato_demo) do
      {:ok, post} ->
        render(conn, :blog_post, post: post)

      {:error, _reason} ->
        conn
        |> put_status(:not_found)
        |> put_view(PlatoDemoWeb.ErrorHTML)
        |> render(:"404")
    end
  end
end

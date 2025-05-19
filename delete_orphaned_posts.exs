Mix.Task.run("app.start")
import Ecto.Query
alias Mstosky.Repo
alias Mstosky.Social.Post

{count, _} = Repo.delete_all(from p in Post, where: is_nil(p.user_id))

module OctoHerder
  LIST_ALL_LABELS_FOR_A_REPOSITORY =
    [{
       "url" => "https =>//api.github.com/repos/octocat/Hello-World/labels/bug",
       "name" => "bug",
       "color" => "f29513"
     }]

  LIST_MILESTONES_FOR_A_REPOSITORY =
    [{
       "url" => "https =>//api.github.com/repos/octocat/Hello-World/milestones/1",
       "number" => 1,
       "state" => "open",
       "title" => "v1.0",
       "description" => "",
       "creator" => {
         "login" => "octocat",
         "id" => 1,
         "avatar_url" => "https =>//github.com/images/error/octocat_happy.gif",
         "gravatar_id" => "somehexcode",
         "url" => "https =>//api.github.com/users/octocat"
       },
       "open_issues" => 4,
       "closed_issues" => 8,
       "created_at" => "2011-04-10T20:09:31Z",
       "due_on" => nil
     }]
end

---
title: "Build a Blog Like This"
date: 2020-01-22T16:58:49-08:00
tags: [Tools]
---


Install Hugo and theme https://github.com/lingxz/er.

```sh
brew install hugo
# verify
hugo version
# blog will be the git folder
hugo new site blog
cd blog/themes
git clone https://github.com/lingxz/er.git
rm -rf er/.git
cd ..
echo 'theme = "er"' >> config.toml
```

Add the a post and test locally,

```sh
hugo new posts/my-first-post.md
echo 'Hello Hugo!' >> content/posts/my-first-post.md
hugo server -D
```

Create a repo on Github.

> Github Pages provides [two types of sites](https://help.github.com/en/github/working-with-github-pages/about-github-pages#types-of-github-pages-sites). But,
> 
> *You cannot choose a different publishing source for user or organization sites.* [^1](https://help.github.com/en/github/working-with-github-pages/about-github-pages#publishing-sources-for-github-pages-sites)
>
> The following steps assume you're using "project site".
>
> If you want to use "user or organization sites", you need another way to manage your raw contents and public static website.

Change `baseURL` in `config.toml` to `https://d4rkb1ue.github.io/blog`

Press Ctrl+C to stop server.

Publish to a new Github Repo.

```sh
git init
hugo -D -d docs

git commit -am"init"

# change to your own git url
git remote add origin git@github.com:d4rkb1ue/blog.git
git push -u origin
```

Set your Github Repo,

1. Go `Settings` panel -> `GitHub Pages` section
2. Change `Source` to `master branch /docs folder`

Test your blog in your browser,

- http://d4rkb1ue.github.io/blog/

*Optionally, you can also change to a custom domain,

1. Go to your Domain DNS provider, add/change the record for the domain you choose to `d4rkb1ue.github.io` (`d4rkb1ue` should be changed to your Github username)
   - For apex domain, make a CNAME record with Name `drkbl.com`, and Content `d4rkb1ue.github.io`
   - For subdomain, make a CNAME record with Name `blog`(anything you want), and Content `d4rkb1ue.github.io`.
2. edit `baseURL` in `config.toml`
3. In `GitHub Pages` setting, type your apex domain or subdomain, for ex, `drkbl.com`


# Ref.

1. https://github.com/lingxz/er
2. https://help.github.com/en/github/working-with-github-pages/managing-a-custom-domain-for-your-github-pages-site#configuring-a-subdomain
3. https://help.github.com/en/github/working-with-github-pages/getting-started-with-github-pages

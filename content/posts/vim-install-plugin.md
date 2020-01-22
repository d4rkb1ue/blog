---
title: "Vim 安装自动缩进插件"
date: 2016-07-20 00:50:35
tags: [Vim, Tools, macOS]
---

以 [vim-javascript](https://github.com/pangloss/vim-javascript) v0.10.0 (为JS提供自动缩进) 为例 

# 安装 Vundle
[vundle](https://github.com/VundleVim/Vundle.vim)让管理插件变得更清晰、智能。

vundle 会接管 .vim/ 下的所有原生目录，所以先清空该目录，再通过如下命令安装 vundle：

```
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```

# 配置 Vundle
新建 `vi ~/.vimrc` vim配置文件

```
" vundle 环境设置
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
" vundle 管理的插件列表必须位于 vundle#begin() 和 vundle#end() 之间
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'pangloss/vim-javascript'

" 插件列表结束
call vundle#end()
filetype plugin indent on

```

配置文件中`Plugin 'pangloss/vim-javascript'`就是要安装的这个插件。

# 执行安装插件

进入vi，执行
```
:PluginInstall
```

最下面一行显示 `Done` 。完成。

# 测试

进入vi，执行

```
gg=G
```

成功的indent了。

---

# 参考

- [像 IDE 一样使用 vim](https://github.com/yangyangwithgnu/use_vim_as_ide)

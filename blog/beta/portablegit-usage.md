**File Name** portablegit-usage.md 

**Description** PortableGit 简明教程  
**Author** LiCunchang(printf@live.com)  
**Version** 1.0.20130327  

------

## 1 简介

msysgit 是 Git 版本控制系统在 Windows 下的版本。PortableGit 是其编写版本，不需要安装。

## 2 下载安装

> **homepage** https://code.google.com/p/msysgit/

去官方网站下载最新版本 **PortableGit-<versionstring>.7z** 解压。打开 **git-bash.bat** 

## 3 设置和使用

git config --global user.name "licunchang"
git config --global user.email printf@live.com

git config --local user.name "licunchang"
git config --local user.email "licunchang@wepiao.com"

git config --global core.autocrlf false
git config --global color.ui auto
git config --global core.ignorecase false
git config --global core.quotepath false

# 新建一个“new_branch”的分支并且切换到改分支
git checkout -b new_branch

# 切换回master分支
git checkout master

#删除本地分支
git branch -d branch_name

#推送分支到远端仓库
git push origin <branch>

#更新本地仓库至最新版本
git pull

#要合并其他分支到你的当前分支（例如master）
git merge <branch>

## git config

git config -l

### system

git config --system -l

git config --system -e

### global

git config --global -l

git config --global -e

### local

git config --local -l

git config --local -e

查看版本历史
git log --pretty=oneline

# 我们要把当前版本“版本4”回退到上一个版本“版本3”
git reset --hard HEAD^

#记录你的每一次命令
git reflog


把暂存区的修改撤销掉（unstage），重新放回工作区
git reset HEAD readme.txt

丢弃工作区的修改
git checkout -- readme.txt









http://www.worldhello.net/git-quiz/exam01.html

git ls-files -d | xargs git checkout --













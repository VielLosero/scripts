#!/bin/bash
#Begin license text.
#Copyleft 2019 Viel Losero
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"),
#to deal in the Software without restriction, including without limitation the rights to use,
#copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
#and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all copies
#or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
#INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
#IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
#DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#End license text.
#https://opensource.org/licenses/MIT

#USAGE:
#This script creates the initial minimal configuration files to start working with the local Hugo server
#for the creation of a static website.

base="/home/user/mi_new_static_website" # change this with the path of work directory
site="mi_blog" # change this with the name of your site 
theme="mi_theme" # change this with the name u want for your hugo theme

echo "[*] Generating basic structure with hugo templates"
mkdir -p $base
cd $base
hugo new site $site
cd $site
hugo new theme $theme
cd ..

echo "[*] Creating baseof.html"
cat <<EOF> $base/$site/themes/$theme/layouts/_default/baseof.html
<!DOCTYPE html>
<html>
    {{- partial "head.html" . -}}
    <body>
        {{- partial "header.html" . -}}
	<section>
		<div id=content>
        	{{- block "article" . }}{{- end }}
		</div>
	</section>
    	{{- partial "footer.html" . -}}
    </body>
</html>
EOF

echo "[*] Creating index.html"
cat <<EOF> $base/$site/themes/$theme/layouts/index.html 
{{ define "article" }}
<main>
    <article>
        <header class="index-header">
            <h1> {{.Title}}</h1>
        </header>
        <!-- "{{.Content}}" pulls from the markdown content of content/_index.md -->
        {{.Content}}
    </article>
</main>
{{ end }}
EOF

echo "[*] Creating list.html"
cat <<EOF> $base/$site/themes/$theme/layouts/_default/list.html 
{{ define "article" }}
<main>
    <article>
        <header class="list-header">
            <h1> {{.Title}}</h1>
		{{ if .IsTranslated }}
		    {{ range .Translations }}
		       [ <a href="{{ .Permalink }}">{{ .Lang }}</a> ]
		    {{ end }}
                {{ end }}                                                                                                                                     
        </header>
        <!-- "{{.Content}}" pulls from the markdown content of the corresponding _index.md -->
        {{.Content}}
    </article>
    <ul>
    <!-- Ranges through content/posts/*.md -->
    {{ range first 5 (where .Site.RegularPages "Type" "post")}}
        <li>
            <a href="{{.Permalink}}">{{.Date.Format "2006-01-02"}} | {{.Title}}</a>
        </li>
    {{ end }}
    </ul>
</main>
{{ end }}
EOF


echo "[*] Creating single.html"
cat <<EOF> $base/$site/themes/$theme/layouts/_default/single.html 
{{ define "article" }}
<main>
    <article>
        <header class="article-header">
            <h1> {{.Title}}</h1>
        </header>
	 <article>
		<div class="post-meta">
		<p id="post-date"> Posted: {{ .Date.Format "Jan 2, 2006" }} - [ {{ .WordCount }} Words ] 
		{{ if .IsTranslated }}
		    {{ range .Translations }}
		       - [ <a href="{{ .Permalink }}">{{ .Lang }}</a> ]
		    {{ end }}
                {{ end }}                                                                                                                                     
		</p>
		</div>
		 <p id="toc">Table of contents {{ .TableOfContents }}</p>
		{{ .Content }}
	 </article>
    </article>
</main>
{{ end }}
EOF

echo "[*] Creating head.html"
cat <<EOF> $base/$site/themes/$theme/layouts/partials/head.html 
<head>
<title>Viel Losero - {{ .Title }}</title>
<link rel="stylesheet" href="/css/main.css"/>
<link rel="stylesheet" href="{{ "css/syntax.css" | absURL }}" />
<link href="https://fonts.googleapis.com/css?family=Nunito|Roboto&display=swap" rel="stylesheet">
</head>
EOF

echo "[*] Creating header.html"
cat <<EOF> $base/$site/themes/$theme/layouts/partials/header.html 
<header class="homepage-header">
<div class="banner">
    <a href="{{ "/" | absURL }}"><img src="/images/logo.svg" alt="logo" /></a>
	<div>
	<a id="name" href="/"><h1>Viel Losero&#39; website</h1></a>
        <nav class="MenuNav"> 
                {{  \$currentPage := . }}                                                                                                                     
                {{ range .Site.Menus.main }}                                                                                                                  
                <a class="sidebar-nav-item{{if or (\$currentPage.IsMenuCurrent "main" .) (\$currentPage.HasMenuCurrent "main" .) }} active{{end}}" href="{{ .URL }}" title="{{ .Title }}">{{ .Name }}</a>
		{{ end }}
        </nav>        
</div>
</div>
</header>
EOF

echo "[*] Creating footer.html"
cat <<EOF> $base/$site/themes/$theme/layouts/partials/footer.html 
<footer>
Copyright © 2019 Viel Losero
</footer>
EOF

echo "[*] Creating config.toml"
cat<<EOF> $base/$site/config.toml 
baseURL = "/"
languageCode = "es"
title = "New $site site"
theme = "$theme"
relativeURLs = true 
EOF

echo "[*] Generating css"
cat<<EOF> $base/$site/themes/$theme/static/css/main.css
/* put here your css config */

EOF

echo "[*] Creating content files"
#rm $base/$site/content/_index.en.md
hugo new  $base/$site/content/_index.en.md 
cat<<EOF> $base/$site/content/_index.en.md 
---
title: "Welcome!"
date: 2019-10-11T11:34:36+02:00
---

Hello and welcome to my site. 
EOF

cat<<EOF> $base/$site/content/_index.es.md 
---
title: "Bienvenidos!"
date: 2019-10-11T11:34:36+02:00
---

Hola y bienvenidos a mi sitio. 
EOF

cat<<EOF> $base/$site/content/about.en.md 
---
title: "About"
date: 2019-10-12T18:03:16+02:00
---
About me.
EOF

cat<<EOF> $base/$site/content/about.es.md 
---
title: "Sobre mi"
date: 2019-10-12T10:15:39+02:00
slug: acerca
---
Sobre mi.
EOF

cat<<EOF> $base/$site/content/contact.en.md 
---
title: "Contact Me"
date: 2019-10-11T10:47:14+02:00
type: "contact"
---

Email: [viel.losero@gmail.com](mailto:viel.losero@gmail.com)

Twitter: [@VLosero](https://twitter.com/VLosero)

GitHub: [VielLosero](https://github.com/VielLosero)
EOF

cat<<EOF> $base/$site/content/contact.es.md 
---
title: "Contacto"
date: 2019-10-11T10:47:14+02:00
type: "contact"
slug: contacto
---

Email: [viel.losero@gmail.com](mailto:viel.losero@gmail.com)

Twitter: [@VLosero](https://twitter.com/VLosero)

GitHub: [VielLosero](https://github.com/VielLosero)
EOF

hugo new  $site/content/posts/post1.md                                                                                                                        
cat<<EOF>> $site/content/posts/post1.md                                                                                                                       
#post number 1                                                                                                                                                
                                                                                                                                                              
content example                                                                                                                                               
                                                                                                                                                              
[link](#)                                                                                                                                                     
EOF

echo "[*] Making dir for images"
mkdir -p $base/$site/content/posts/images/
# to link images on posts --> [image alternate text](/en/posts/images/file.png)

echo "[*] Generating pygments"
# from https://gohugo.io/content-management/syntax-highlighting/#generate-syntax-highlighter-css
hugo gen chromastyles --style=solarized-dark256 > $base/$site/themes/$theme/static/css/syntax.css
cat<<EOF>> $base/$site/config.toml
pygmentsUseClasses=true
pygmentsCodeFences=true
defaultContentLanguage = "en"
defaultContentLanguageInSubdir=true
EOF

echo "[*] Generating Multilanguage Menu"
# from https://gohugo.io/templates/menu-templates/
cat<<EOF>> $base/$site/config.toml
sectionPagesMenu = "main"

[languages]
  [languages.en]
	title = "Viel Losero's Website"
	languageName = "English"
	weight = 1
  [[languages.en.menu.main]]
	identifier = "about"
	name = "About"
	url = "/en/about/"
	weight = 120

  [[languages.en.menu.main]]
	identifier = "contact"
	name = "Contact"
	url = "/en/contact/"
	weight = 110

  [[languages.en.menu.main]]
	identifier = "posts"
	name = "Posts"
	url = "/en/posts/"
	weight = 100

  [languages.es]
	title = "Pagina Web de Viel Losero"
	languageName = "Spanish"
	weight = 2
  [[languages.es.menu.main]]
	identifier = "about"
	name = "Acerca"
	url = "/es/acerca/"
	weight = 120

  [[languages.es.menu.main]]
	identifier = "contact"
	name = "Contacto"
	url = "/es/contacto/"
	weight = 110

  [[languages.es.menu.main]]
	posts = "publicaciones"
	identifier = "posts"
	name = "Publicaciones"
	url = "/es/posts/"
	weight = 100
EOF

echo "[*] Making dir for static images like logo"
mkdir -p $base/$site/static/images/
# copy the logo to -->
#cp logo.svg $base/$site/static/images/

echo "[*] Starting Hugo Server"
cd $base
cd $site
hugo server -D 



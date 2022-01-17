---
title: "Amps Template Engine"
tags: ['C++']
date: 2019-01-08T17:20:19-08:00
draft: false
author: "Jose R. Ziviani"
showToc: true
TocOpen: false
comments: false
disableHLJS: true
searchHidden: true
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
summary: "Amps template engine for C++17."
---
[Amps](https://github.com/jrziviani/amps) is my new toy project. I've been writing it after reading the [Crafting Interpreters](http://craftinginterpreters.com/), an excellent book by the way. Amps is a simple text template engine (under development, of course) developed in C++17.

As a side note, I'm impressed with modern C++ expressiveness. Despite of critics that I've read recently, it's becoming a lot easier than old C++. Features like `optional` and `variant` give us the power to compose different types in order to create type safe complex structures, almost like dynamically type languages do.

For instance:

{{< highlight cpp >}}
    amps::user_map ht {
      {"name", "My name"},
      {"cities", vector{
             "Sao Paulo",
             "Paris",
             "NYC",
             "London",
             "Lisbon"}},
      {"songs", unordered_map{
            {"guns and roses", "patience"},
            {"aerosmith", "crazy"},
            {"led zeppelin", "immigrant song"},
            {"pink floyd", "high hopes"}}},
    };
{{< / highlight >}}

Isn't it somewhat similar to Python?

{{< highlight python >}}
    ht = {
        "name": "My name",
        "cities": ["Sao Paulo", "Paris"],
        "songs": {"aerosmith": "crazy"}}
{{< / highlight >}}

To make Amps more useful I've integrated it to a module for [Apache HTTP server](https://httpd.apache.org/). It basically offers dynamic web pages without a real programming language (like PHP, Ruby, Python) behind it. This could be good for small projects, however I've not measure the performance yet.

In order to build Apache's HTTPd I referred to my [old post](https://ziviani.net/2011/how-to-create-an-apache-module). Then, I wrote a wrapper to connect my C++17 project with an plain C Apache module and nothing else.

{{< highlight console >}}
    $ cat amps_wrapper.cpp
{{< / highlight >}}

{{< highlight cpp "linenos=inline" >}}
    #ifdef __cplusplus
    
    #include "engine.h"
    
    #include "httpd.h"
    
    #include <unordered_map>
    #include <vector>
    #include <string>
    #include <cstring>
    
    using std::vector;
    using std::string;
    using std::unordered_map;
    
    unordered_map<string, string> query_to_map(const char *query)
    {
        unordered_map<string, string> result;
        if (query == nullptr) {
            return result;
        }
    
        char *tmp = strdup(query);
        for (char *tok = strtok(tmp, "&"); tok != NULL; tok = strtok(NULL, "&")) {
            char *value = strchr(tok, '=');
            if (value == nullptr) {
                continue;
            }
    
            result[string(tok, value - tok)] = string(&value[1]);
        }
    
        free(tmp);
        return result;
    }
    
    static void get_custom_template(request_rec *r, char **result)
    {
        if (r->args == 0) {
            return;
        }
    
        amps::error err;
        amps::engine engine(err);
        engine.set_template_directory("/tmp");
    
        amps::user_map ht {{"user_data", query_to_map(r->args)}};
    
        // html template is the default, xml returned when content=xml
        auto content = user.find("content");
        if (content == user.end() || content->second == "html") {
            engine.prepare_template("template.tpl");
            r->content_type = "text/html";
        }
        else {
            engine.prepare_template("template_xml.tpl");
            r->content_type = "text/xml";
        }
        string rendered = engine.render(ht);
    
        *result = (char*)malloc(sizeof(char) * rendered.size() + 1);
        strcpy(*result, rendered.c_str());
        (*result)[rendered.size()] = '\0';
    }
    #endif
    
    extern "C" {
        #include "amps_wrapper.h"
    
        void get_template(request_rec *r, char **result)
        {
            get_custom_template(r, result);
        }
    }
{{< / highlight >}}

The HTTPd module simply calls the `get_template` function.

{{< highlight cpp "linenos=inline" >}}
    static int get_handler(request_rec *r)
    {
        char *result = NULL;
    
        if (r->header_only || r->args == 0) {
            return OK;
        }
    
        get_template(r, &result);
    
        /* something bad happened */
        if (result == NULL) {
            return DECLINED;
        }
    
        ap_rputs(result, r);
    
        free(result);
    
        return OK;
    }
{{< / highlight >}}

I compile it all with:

{{< highlight console >}}
    $ g++ -std=c++17 -I/home/ziviani/amps/include \
     -I/home/ziviani/httpd/www/include \
     -fPIC amps_wrapper.cpp -o wrapper.o -c -g3
    $ ../bin/apxs  -I/home/ziviani/amps/include -c -i mod_cool_framework.c wrapper.o libamps-static.a
{{< / highlight >}}

And I finally get this (html template):

{{< highlight html "linenos=inline" >}}
    <html>
        <head>
            <meta charset="utf-8">
        <head>
    
        <body>
            <h2>Welcome {= user_data["name"] =}<h2>
            <ul>
                <li>ALL DATA:<ul>
                {% for key, value in user_data %}
                    {% if value eq "<null>" %}
                        <li>ops, something wrong here<li>
                    {% else %}
                        <li>{= value =}<li>
                    {% endif %}
                {% endfor %}
            <ul>
        <body>
    <html>
{{< / highlight >}}

![amps html content](/amps_html.png)

and this (xml template):

{{< highlight xml "linenos=inline" >}}
    <xml>
        <user_name>{= user_data["name"] =}</user_name>
    </xml>
{{< / highlight >}}

![amps xml content](/amps_xml.png)

Amps is at its initial stage but it's been very fun to develop. I intend to continue writing about it in the near future.

Thank you for reading it.

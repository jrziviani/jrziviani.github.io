---
title: "How to Create an Apache Module"
tags: ['C', 'apache', 'web']
date: 2011-01-10T13:41:20-08:00
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
summary: "A simple how-to guiding through the process of creating an Apache HTTPd module in C language."
---

> **Update**: I wrote a HOWTO guide on how to create an Apache HTTPd module years ago. This is an updated version of the same, that can be found in [github](https://github.com/jrziviani/apache_module).

Write your own httpd module could be interesting for a number of reasons:
*   understand how a webserver works;
*   understand Apache httpd;
*   speed up your current system by optimizing a specific bottleneck;
*   instrumentation;
*   fun?

### Warming up

So, let's jump into it. First step is to clone the HTTPd code and build it.

{{< highlight console >}}
    $ git clone https://github.com/apache/httpd.git
    $ cd httpd
    $ git clone https://github.com/apache/apr.git srclib/apr
    $ ./buildconf
    $ mkdir mybuild
    $ cd mybuild
    $ CFLAGS="-O0 -ggdb" ../configure --enable-rewrite --enable-so --prefix=/home/ziviani/www
    $ make -j 5
    $ make install
    $ cd /home/ziviani/www
    $ ls
    bin  build  cgi-bin  conf  error  htdocs  icons  include  lib  logs  man  manual  modules
{{< / highlight >}}

Check whether the server is working (I set it with high port to run it as a normal user):

{{< highlight console >}}
    $ # still in /home/ziviani/www
    $ vi conf/httpd.conf
    ...
    LISTEN 9898
    ...
    ServerName localhost:9898
    ...
    
    $ bin/apachectl -k start
{{< / highlight >}}

![apache initial works page](/apache_works1.png)

{{< highlight console >}}
    $ bin/apachectl -k stop
{{< / highlight >}}

### My Module

Now we have the httpd source code that compiles and runs, let's create our first module.

{{< highlight console >}}
    $ bin/apxs -g -n my_fast_server
    Creating [DIR]  my_fast_server
    Creating [FILE] my_fast_server/Makefile
    Creating [FILE] my_fast_server/modules.mk
    Creating [FILE] my_fast_server/mod_my_fast_server.c
    Creating [FILE] my_fast_server/.deps
    
    $ vim my_fast_server/mod_my_fast_server.c
{{< / highlight >}}

Easy thing, huh? `apxs` just created a template (thanks to -g option) for us. The instructions in the comment section explains how to build and configure it.

{{< highlight c "linenos=inline" >}}
    /*
    **  mod_my_fast_server.c -- Apache sample my_fast_server module
    **  [Autogenerated via ``apxs -n my_fast_server -g'']
    **
    **  To play with this sample module first compile it into a
    **  DSO file and install it into Apache's modules directory 
    **  by running:
    **
    **    $ apxs -c -i mod_my_fast_server.c
    **
    **  Then activate it in Apache's httpd.conf file for instance
    **  for the URL /my_fast_server in as follows:
    **
    **    #   httpd.conf
    **    LoadModule my_fast_server_module modules/mod_my_fast_server.so
    **    <Location /my_fast_server>
    **    SetHandler my_fast_server
    **    </Location>
    **
    **  Then after restarting Apache via
    **
    **    $ apachectl restart
    **
    **  you immediately can request the URL /my_fast_server and watch for the
    **  output of this module. This can be achieved for instance via:
    **
    **    $ lynx -mime_header http://localhost/my_fast_server 
    **
    **  The output should be similar to the following one:
    **
    **    HTTP/1.1 200 OK
    **    Date: Tue, 31 Mar 1998 14:42:22 GMT
    **    Server: Apache/1.3.4 (Unix)
    **    Connection: close
    **    Content-Type: text/html
    **
    **    The sample page from mod_my_fast_server.c
    */
    #include "httpd.h"
    #include "http_config.h"
    #include "http_protocol.h"
    #include "ap_config.h"
    
    /* The sample content handler */
    static int my_fast_server_handler(request_rec *r)
    {
        if (strcmp(r->handler, "my_fast_server")) {
            return DECLINED;
        }
        r->content_type = "text/html";      
    
        if (!r->header_only)
            ap_rputs("The sample page from mod_my_fast_server.c\n", r);
        return OK;
    }
    
    static void my_fast_server_register_hooks(apr_pool_t *p)
    {
        ap_hook_handler(my_fast_server_handler, NULL, NULL, APR_HOOK_MIDDLE);
    }
    
    /* Dispatch list for API hooks */
    module AP_MODULE_DECLARE_DATA my_fast_server_module = {
        STANDARD20_MODULE_STUFF, 
        NULL,                  /* create per-dir    config structures */
        NULL,                  /* merge  per-dir    config structures */
        NULL,                  /* create per-server config structures */
        NULL,                  /* merge  per-server config structures */
        NULL,                  /* table of config file commands       */
        my_fast_server_register_hooks  /* register hooks              */
    };
{{< / highlight >}}

I made some changes in `mod_my_fast_server.c`. Nothing big, just make it prints browser's query string.

{{< highlight c "linenos=inline" >}}
    #include "httpd.h"
    #include "http_config.h"
    #include "http_protocol.h"
    #include "ap_config.h"
    
    #define MAX_HANDLER 4
    
    typedef int (*method_handler)(request_rec *r);
    
    // HTTP Get method handler
    static int get_handler(request_rec *r);
    
    // HTTP Post method handler
    static int post_handler(request_rec *r);
    
    // HTTP Put method handler
    static int put_handler(request_rec *r);
    
    // HTTP Delete method handler
    static int delete_handler(request_rec *r);
    
    /* The sample content handler */
    static int my_fast_server_handler(request_rec *r)
    {
        if (strcmp(r->handler, "my_fast_server")) {
            return DECLINED;
        }
        r->content_type = "text/html";      
    
        // as per httpd.h r->method_number gives a numeric representation of http
        // method: 0 - get, 1 - put, 2 - post, 3 - delete, etc
        method_handler methods[MAX_HANDLER] = {&get_handler, &put_handler,
            &post_handler, &delete_handler};
    
        if (r->method_number >= MAX_HANDLER || r->method_number < 0) {
            return DECLINED;
        }
    
        // call the handler function
        return methods[r->method_number](r);
    }
    
    static int get_handler(request_rec *r)
    {
        apr_status_t rv;
        int i = 0;
        int n = 0;
        char* query = r->args; // query string
    
        // mime type send to the called
        r->content_type = "text/html";
    
        // return OK if only header requested or no argument
        if (r->header_only || r->args == 0) {
            return OK;
        }
    
        ap_rprintf(r, "<h1>[GET] Your query string: %s</h1>", query);
    
        return OK;
    }
    
    // Post http handler
    static int post_handler(request_rec *r)
    {
        return OK;
    }
    
    // Put http handler
    static int put_handler(request_rec *r)
    {
        return OK;
    }
    
    // Delete http handler
    static int delete_handler(request_rec *r)
    {
        return OK;
    }
    
    static void my_fast_server_register_hooks(apr_pool_t *p)
    {
        ap_hook_handler(my_fast_server_handler, NULL, NULL, APR_HOOK_MIDDLE);
    }
    
    /* Dispatch list for API hooks */
    module AP_MODULE_DECLARE_DATA my_fast_server_module = {
        STANDARD20_MODULE_STUFF, 
        NULL,                  /* create per-dir    config structures */
        NULL,                  /* merge  per-dir    config structures */
        NULL,                  /* create per-server config structures */
        NULL,                  /* merge  per-server config structures */
        NULL,                  /* table of config file commands       */
        my_fast_server_register_hooks  /* register hooks              */
    };
{{< / highlight >}}

Now, compile it to build a DSO and install that DSO in the modules directory (`apxs` does that automatically):

{{< highlight console >}}
    $ bin/apxs -c -i my_fast_server/mod_my_fast_server.c
    
    /home/ziviani/www/build/libtool --silent --mode=compile gcc ...
    ...
    ----------------------------------------------------------------------
    Libraries have been installed in:
       /home/ziviani/www/modules
    
    If you ever happen to want to link against installed libraries
    in a given directory, LIBDIR, you must either use libtool, and
    specify the full pathname of the library, or use the '-LLIBDIR'
    flag during linking and do at least one of the following:
       - add LIBDIR to the 'LD_LIBRARY_PATH' environment variable
         during execution
       - add LIBDIR to the 'LD_RUN_PATH' environment variable
         during linking
       - use the '-Wl,-rpath -Wl,LIBDIR' linker flag
       - have your system administrator add LIBDIR to '/etc/ld.so.conf'
    
    See any operating system documentation about shared libraries for
    more information, such as the ld(1) and ld.so(8) manual pages.
    ----------------------------------------------------------------------
    chmod 755 /home/ziviani/www/modules/mod_my_fast_server.so
{{< / highlight >}}

And that's all! You only need to configure `httpd.conf`, start the server and use it.

{{< highlight console >}}
    $ vim conf/httpd.conf
    ...
    LoadModule my_fast_server_module modules/mod_my_fast_server.so
    <Location /my_fast_server>
        SetHandler my_fast_server
    </Location>
    ...
    
    $ bin/apachectl -k start
{{< / highlight >}}

Open your browse and navigate it to `http://localhost:9898/my_fast_server?test&query=bla` to see the query string printed.

![apache initial works page](/apache_works2.png)

### Extra: static (no apxs) build

Suppose you don't want to use `apxs` and want to build your module together with httpd itself.

I'll reuse the same source file and add my module in the Apache httpd build system. The steps are following:

*   copy the my\_fast\_server folder into httpd main source folder;
*   add my\_fast\_server in httpd build system;
*   call buildconf again to re-generate autoconf;
*   build!

Example:

{{< highlight console >}}
    $ cp -a my_fast_server ~/httpd/modules/
    $ cd ~/httpd
    
    $ vim my_fast_server/config.m4
    
    APACHE_MODPATH_INIT(my_fast_server)
    APACHE_MODULE(my_fast_server, My FAST server!, , , no)
    APACHE_MODPATH_FINISH
    
    $ vim my_fast_server/Makefile.in
    
    include $(top_srcdir)/build/special.mk
    
    $ ./buildconf
    
    $ cd mybuild
    $ ../configure --help
    ...
      --disable-version       determining httpd version in config files
      --enable-remoteip       translate header contents to an apparent client
                              remote_ip
      --enable-my-fast-server My FAST!! server  <===== Yay!!!
      --enable-proxy          Apache proxy module
      --enable-proxy-connect  Apache proxy CONNECT module. Requires
    ...
    
    $ CFLAGS="-O0 -ggdb" ../configure --enable-rewrite --enable-so --enable-my-fast-server --prefix=/home/ziviani/www
    $ make
    $ make install
{{< / highlight >}}

If the build finished without any errors, you can test your new module. Go to the `www` folder, edit `conf/httpd.conf` and start the server.

{{< highlight console >}}
    $ vim conf/httpd.conf
    ...
    LoadModule my_fast_server_module modules/mod_my_fast_server.so
    <Location /my_fast_server>
        SetHandler my_fast_server
    </Location>
    ...
    
    $ bin/apachectl -k start
{{< / highlight >}}

Navigate it to `http://localhost:9898/my_fast_server?test&query=bla` to see the query string printed.

![apache initial works page](/apache_works3.png)

### References

*   [http://apr.apache.org/docs/apr/1.4/modules.html](https://apr.apache.org/docs/apr/1.4/modules.html)
*   [http://httpd.apache.org/docs/2.1/](https://httpd.apache.org/docs/2.1/)
*   [http://httpd.apache.org/docs/2.1/mod/mod\_dbd.html](https://httpd.apache.org/docs/2.1/mod/mod_dbd.html)
*   [http://blog.projectfondue.com/2009/8/25/apache-moving-from-prefork-to-worker](http://blog.projectfondue.com/2009/8/25/apache-moving-from-prefork-to-worker)
